import 'package:flutter_test/flutter_test.dart';
import 'package:testmaster_viewer/domain/calendar_day.dart';
import 'package:testmaster_viewer/domain/device.dart';
import 'package:testmaster_viewer/domain/filters.dart';

const reference = CalendarDay(2026, 9, 5);
DeviceRecord device(
  String id, {
  String next = '',
  String last = '',
  String location = 'Room 2',
  String customer = '1',
  String description = 'Drill',
  String result = 'OK',
}) => DeviceRecord(
  {
    'IDNumber': id,
    'CustomerNumber': customer,
    'NextTest': next,
    'LastTest': last,
    'Location': location,
    'DeviceDescription': description,
    'TestResult': result,
  },
  {'1': 'Example company', '2': 'Second company'},
);
String offset(int days) {
  final value = DateTime.utc(2026, 9, 5 + days);
  return CalendarDay(value.year, value.month, value.day).iso;
}

void main() {
  group('Calendar days', () {
    test('Parses database timestamps without shifting timezones', () {
      expect(CalendarDay.parse('2026-09-05 23:59:59')?.iso, '2026-09-05');
      expect(CalendarDay.parse('2026-09-05T00:00:00+02:00')?.iso, '2026-09-05');
    });
    test('Checks leap years and rejects normalized invalid dates', () {
      expect(CalendarDay.parse('2024-02-29'), const CalendarDay(2024, 2, 29));
      for (final input in [
        '2026-02-29',
        '2026-13-01',
        '2026-04-31',
        '2026-00-00',
        '0000-01-01',
        '2026-09-05evil',
        'not a date',
        '',
      ]) {
        expect(CalendarDay.parse(input), isNull, reason: input);
      }
    });
    test('Uses calendar days across spring and autumn DST changes', () {
      expect(
        const CalendarDay(
          2026,
          3,
          30,
        ).difference(const CalendarDay(2026, 3, 28)),
        2,
      );
      expect(
        const CalendarDay(
          2026,
          10,
          26,
        ).difference(const CalendarDay(2026, 10, 24)),
        2,
      );
    });
    test('Reference date bounds are explicit', () {
      expect(CalendarDay.parseReference('1899-12-31'), isNull);
      expect(CalendarDay.parseReference('1900-01-01'), isNotNull);
      expect(CalendarDay.parseReference('9999-12-31'), isNotNull);
      expect(CalendarDay.parseReference('2026-09-05T12:00'), isNull);
    });
    test('Moves through year boundaries and formats dates and counts', () {
      expect(
        const CalendarDay(2026, 12, 31).monthStart(1),
        const CalendarDay(2027, 1, 1),
      );
      expect(reference.display, '05.09.2026');
      expect(formatCount(1525), '1’525');
    });
  });

  group('Device records', () {
    test('Preserves leading zeros, raw result codes and customer identity', () {
      final a = device('00123', customer: '1', result: ' f ');
      final b = device('00123', customer: '2');
      expect(a.id, '00123');
      expect(a.value('TestResult'), ' f ');
      expect(a.resultCode, 'F');
      expect(a.identity, isNot(b.identity));
      expect(a.customerName, 'Example company');
    });
    test('Falls back to customer numbers, never fixed branding', () {
      expect(DeviceRecord.resolveCustomer('0042', {}), 'Kunde 0042');
      expect(DeviceRecord.resolveCustomer('', {}), 'Kunde nicht angegeben');
    });
    test('Normalizes search accents and multiple tokens', () {
      expect(normalizeSearch('KÜCHE Straße'), 'kuche strasse');
      expect(searchTokens('  room   2 '), ['room', '2']);
    });
    test('Sorts numeric portions naturally', () {
      final values = ['Room 10', 'Room 2', 'Room 1']..sort(naturalCompare);
      expect(values, ['Room 1', 'Room 2', 'Room 10']);
      expect(naturalCompare('002', '2'), 0);
    });
    for (final entry in <int, DueStatus>{
      -1: DueStatus.overdue,
      0: DueStatus.today,
      1: DueStatus.soon,
      30: DueStatus.soon,
      31: DueStatus.medium,
      90: DueStatus.medium,
      91: DueStatus.later,
    }.entries) {
      test('Classifies due boundary ${entry.key} days', () {
        expect(
          device('1', next: offset(entry.key)).due(reference),
          entry.value,
        );
      });
    }
    test('Does not infer a missing or invalid date', () {
      expect(device('1').due(reference), DueStatus.missing);
      expect(device('2', next: '2026-02-30').due(reference), DueStatus.missing);
    });
    test('Reads optional and null fields safely', () {
      final result = InspectionSnapshot.fromJson({
        'devices': [
          {'IDNumber': '001', 'CustomerNumber': '42', 'NextTest': null},
        ],
        'customers': [
          {'CustomerNumber': '42', 'Name': 'Test customer'},
        ],
      });
      expect(result.devices.single.id, '001');
      expect(result.devices.single.customerName, 'Test customer');
      expect(result.devices.single.nextDay, isNull);
    });
  });

  group('Filtering and sorting', () {
    final records = [
      device(
        '1',
        next: offset(-1),
        location: 'Küche',
        description: 'Monitor A',
        result: 'F',
      ),
      device(
        '2',
        next: offset(0),
        location: 'Room 2',
        description: 'Monitor B',
      ),
      device('10', next: offset(30), location: 'Room 10', result: ''),
      device('3', next: offset(31), location: '', result: 'P'),
      device('4', next: 'invalid', location: 'Room 2'),
    ];
    test('Combines multiple locations using OR', () {
      final filters = ViewerFilters(locations: {'Küche', 'Room 10'});
      expect(filterDevices(records, filters, reference).map((row) => row.id), [
        '1',
        '10',
      ]);
    });
    test('Supports an explicitly selected empty location', () {
      expect(scopeDevices(records, {''}).single.id, '3');
      expect(scopeDevices(records, {}).length, records.length);
    });
    test('Uses AND between search tokens', () {
      final filters = ViewerFilters(search: 'MONITOR kuche');
      expect(filterDevices(records, filters, reference).single.id, '1');
    });
    test('Search includes customer names', () {
      final filters = ViewerFilters(
        search: 'example company',
        locations: {'Küche'},
      );
      expect(filterDevices(records, filters, reference).single.id, '1');
    });
    test('Upcoming 30 days include today and exclude day 31', () {
      expect(
        filterDevices(
          records,
          ViewerFilters(due: 'soon'),
          reference,
        ).map((row) => row.id),
        ['2', '10'],
      );
    });
    test('Raw result groups remain distinct', () {
      expect(
        filterDevices(records, ViewerFilters(result: 'F'), reference).single.id,
        '1',
      );
      expect(
        filterDevices(
          records,
          ViewerFilters(result: 'empty'),
          reference,
        ).single.id,
        '10',
      );
      expect(
        filterDevices(
          records,
          ViewerFilters(result: 'other'),
          reference,
        ).single.id,
        '3',
      );
    });
    test('Invalid dates remain at the bottom in both directions', () {
      for (final descending in [false, true]) {
        expect(
          filterDevices(
            records,
            ViewerFilters(descending: descending),
            reference,
          ).last.id,
          '4',
        );
      }
    });
    test('Rejects invalid persisted settings and respects page bounds', () {
      final filters = ViewerFilters.fromJson({
        'pageSize': 1000,
        'horizonMonths': 7,
        'referenceDate': '2026-02-30',
        'due': 'unsafe',
        'sort': 'bad:desc',
        'locations': ['A', 4],
      });
      expect(filters.pageSize, 25);
      expect(filters.horizonMonths, 12);
      expect(filters.manualDate, isNull);
      expect(filters.due, '*');
      expect(filters.sortField, 'NextTest');
      expect(filters.locations, {'A'});
    });
    test('Round trips all public settings', () {
      final original = ViewerFilters(
        locations: {'Room 2', 'Room 10'},
        search: 'Monitor',
        due: 'soon',
        result: 'F',
        sortField: 'Location',
        descending: true,
        month: '2026-09',
        pageSize: 100,
        horizonMonths: 60,
        manualDate: reference,
      );
      expect(
        ViewerFilters.fromJson(original.toJson()).toJson(),
        original.toJson(),
      );
    });
  });

  group('Dashboard calculations', () {
    test('Partitions every device exactly once', () {
      final rows = [
        for (final days in [-1, 0, 30, 31, 91])
          device('$days', next: offset(days)),
        device('missing', result: 'F'),
      ];
      final counts = DashboardCounts.fromDevices(rows, reference);
      expect(counts.total, 6);
      expect(counts.counts.values.reduce((a, b) => a + b), 6);
      expect(counts.soon, 2);
      expect(counts.failed, 1);
    });
    test(
      'Forecast excludes overdue rows and preserves partial current month',
      () {
        final rows = [
          device('past', next: '2026-09-04'),
          device('today', next: '2026-09-05'),
          device('end', next: '2026-09-30'),
          device('next', next: '2026-10-01'),
          device('outside', next: '2027-09-01'),
          device('missing'),
        ];
        final values = forecast(rows, reference, 12);
        expect(values.length, 12);
        expect(values.first.count, 2);
        expect(values[1].count, 1);
        expect(values.last.start.monthKey, '2027-08');
        expect(values.fold<int>(0, (total, value) => total + value.count), 3);
        expect(
          filterDevices(
            rows,
            ViewerFilters(month: '2026-09'),
            reference,
          ).map((row) => row.id),
          ['today', 'end'],
        );
      },
    );
    for (final months in horizons) {
      test('Produces precisely $months forecast buckets', () {
        expect(forecast([], reference, months).length, months);
      });
    }
    test('Forecast and clicked month respect location scope', () {
      final rows = [
        device('a', next: offset(1), location: 'A'),
        device('b', next: offset(1), location: 'B'),
      ];
      final scope = scopeDevices(rows, {'A'});
      expect(forecast(scope, reference, 12).first.count, 1);
      expect(
        filterDevices(
          rows,
          ViewerFilters(locations: {'A'}, month: '2026-09'),
          reference,
        ).single.id,
        'a',
      );
    });
  });
}
