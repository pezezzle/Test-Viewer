import 'package:flutter_test/flutter_test.dart';
import 'package:testmaster_viewer/data/demo_store.dart';
import 'package:testmaster_viewer/data/platform_store.dart';
import 'package:testmaster_viewer/domain/calendar_day.dart';
import 'package:testmaster_viewer/domain/device.dart';
import 'package:testmaster_viewer/state/viewer_controller.dart';

class TestStore extends DemoViewerStore {
  bool failRead = false;
  String sourceId = 'test-source';
  TestStore() : super(reference: const CalendarDay(2026, 9, 5));
  @override
  Future<SourceConfiguration> configuration() async => SourceConfiguration(
    folder: sourceId,
    sourceId: sourceId,
    configured: true,
  );
  @override
  Future<InspectionSnapshot> read() async {
    if (failRead) throw StateError('Test read failure');
    return super.read();
  }
}

void main() {
  late TestStore store;
  late ViewerController controller;
  var now = DateTime(2026, 9, 5, 23, 59);
  setUp(() {
    now = DateTime(2026, 9, 5, 23, 59);
    store = TestStore();
    controller = ViewerController(store: store, clock: () => now);
  });
  tearDown(() async {
    await controller.flushSettings();
    controller.dispose();
  });

  test('Initial read populates the snapshot and first 25 rows', () async {
    await controller.initialize();
    expect(controller.snapshot?.devices.length, 80);
    expect(controller.pageRows.length, 25);
    expect(controller.totalPages, 4);
    expect(controller.busy, false);
  });
  test(
    'Failed refresh keeps the previous data with explicit stale state',
    () async {
      await controller.initialize();
      final previous = controller.snapshot;
      store.failRead = true;
      await controller.refresh();
      expect(controller.snapshot, same(previous));
      expect(controller.stale, true);
      expect(controller.error, isNotNull);
      store.failRead = false;
      await controller.refresh();
      expect(controller.stale, false);
      expect(controller.error, isNull);
    },
  );
  test('Automatic reference date changes at midnight', () async {
    await controller.initialize();
    controller.filters.month = '2026-09';
    now = DateTime(2026, 9, 6);
    controller.synchronizeDay();
    expect(controller.reference, const CalendarDay(2026, 9, 6));
    expect(controller.filters.month, isEmpty);
  });
  test('Manual reference survives refresh and clock changes', () async {
    await controller.initialize();
    controller.setReference(const CalendarDay(2027, 1, 15));
    now = DateTime(2026, 9, 7);
    controller.synchronizeDay();
    await controller.refresh();
    expect(controller.reference, const CalendarDay(2027, 1, 15));
    await controller.flushSettings();
    expect(store.settings['referenceDate'], '2027-01-15');
    controller.setReference(null);
    expect(controller.reference, const CalendarDay(2026, 9, 7));
  });
  test('Settings restore multiple locations and forecast horizon', () async {
    store.settings = {
      'locations': ['Werkstatt', 'Küche'],
      'horizonMonths': 60,
      'pageSize': 5,
      'referenceDate': '2027-01-01',
    };
    await controller.initialize();
    expect(controller.filters.locations, {'Werkstatt', 'Küche'});
    expect(controller.filters.horizonMonths, 60);
    expect(controller.pageRows.length, 5);
    expect(controller.reference, const CalendarDay(2027, 1, 1));
  });
  test('Drill down retains selected locations', () async {
    await controller.initialize();
    controller.setLocations({'Werkstatt', 'Küche'});
    controller.openFiltered(due: 'overdue');
    expect(controller.tab, 1);
    expect(controller.filters.locations, {'Werkstatt', 'Küche'});
    expect(
      controller.filtered.every(
        (row) => row.due(controller.reference) == DueStatus.overdue,
      ),
      true,
    );
  });
  test('Pagination clamps after filtering', () async {
    await controller.initialize();
    controller.setPage(3);
    expect(controller.pageRows.length, 5);
    controller.filters.search = 'no-matching-device';
    controller.changed();
    expect(controller.pageRows, isEmpty);
    expect(controller.page, 0);
    expect(controller.totalPages, 1);
  });
  test('Changing source does not mix cached data and old scope', () async {
    await controller.initialize();
    controller.setLocations({'Werkstatt'});
    controller.filters.search = 'old query';
    store.sourceId = 'another-source';
    await controller.chooseFolder();
    expect(controller.snapshot, isNull);
    expect(controller.filters.locations, isEmpty);
    expect(controller.filters.search, isEmpty);
  });
  test('Customer heading is derived from the selected devices', () async {
    await controller.initialize();
    expect(controller.customerHeading, '2 Kunden');
    controller.snapshot = InspectionSnapshot(
      devices: [
        DeviceRecord(
          {'IDNumber': '001', 'CustomerNumber': '123'},
          {'123': 'Independent customer'},
        ),
      ],
      customers: {'123': 'Independent customer'},
      sourceLabel: 'test',
      sourceId: 'test',
      readAt: '2026-09-05',
    );
    expect(controller.customerHeading, 'Independent customer');
  });
}
