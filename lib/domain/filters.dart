import 'calendar_day.dart';
import 'device.dart';

const pageSizes = [5, 10, 25, 50, 100];
const horizons = [12, 24, 36, 48, 60];
const sortFields = [
  'NextTest',
  'Location',
  'IDNumber',
  'DeviceDescription',
  'Manufacturer',
  'LastTest',
  'TestResult',
];

class ViewerFilters {
  Set<String> locations;
  String search;
  String due;
  String result;
  String sortField;
  bool descending;
  String month;
  int pageSize;
  int horizonMonths;
  CalendarDay? manualDate;

  ViewerFilters({
    Set<String>? locations,
    this.search = '',
    this.due = '*',
    this.result = '*',
    this.sortField = 'NextTest',
    this.descending = false,
    this.month = '',
    this.pageSize = 25,
    this.horizonMonths = 12,
    this.manualDate,
  }) : locations = locations ?? <String>{};

  factory ViewerFilters.fromJson(Map<String, Object?> json) {
    final selected = json['locations'];
    final sort = (json['sort']?.toString() ?? 'NextTest:asc').split(':');
    final due = json['due']?.toString() ?? '*';
    final result = json['result']?.toString() ?? '*';
    final size = int.tryParse('${json['pageSize']}') ?? 25;
    final horizon = int.tryParse('${json['horizonMonths']}') ?? 12;
    final month = json['month']?.toString() ?? '';
    return ViewerFilters(
      locations: selected is List
          ? selected.whereType<String>().toSet()
          : <String>{},
      search: json['search'] is String ? json['search']! as String : '',
      due:
          [
            '*',
            'overdue',
            'today',
            'soon',
            'medium',
            'later',
            'missing',
          ].contains(due)
          ? due
          : '*',
      result: ['*', 'OK', 'F', 'empty', 'other'].contains(result)
          ? result
          : '*',
      sortField: sortFields.contains(sort.first) ? sort.first : 'NextTest',
      descending: sort.length > 1 && sort[1] == 'desc',
      month: RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) ? month : '',
      pageSize: pageSizes.contains(size) ? size : 25,
      horizonMonths: horizons.contains(horizon) ? horizon : 12,
      manualDate: CalendarDay.parseReference(json['referenceDate']),
    );
  }

  Map<String, Object?> toJson() => {
    'locations': locations.toList()..sort(naturalCompare),
    'search': search,
    'due': due,
    'result': result,
    'sort': '$sortField:${descending ? 'desc' : 'asc'}',
    'month': month,
    'pageSize': pageSize,
    'horizonMonths': horizonMonths,
    'referenceDate': manualDate?.iso ?? '',
  };
  CalendarDay reference([DateTime? now]) =>
      manualDate ?? CalendarDay.today(now);
  void clearSearchScope() {
    locations.clear();
    search = '';
    due = '*';
    result = '*';
    month = '';
  }
}

List<DeviceRecord> scopeDevices(
  List<DeviceRecord> records,
  Set<String> locations,
) => locations.isEmpty
    ? records
    : records.where((device) => locations.contains(device.location)).toList();

List<DeviceRecord> filterDevices(
  List<DeviceRecord> records,
  ViewerFilters filters,
  CalendarDay reference,
) {
  final tokens = searchTokens(filters.search);
  final filtered = scopeDevices(records, filters.locations).where((device) {
    final status = device.due(reference);
    final dueMatches =
        filters.due == '*' ||
        (filters.due == 'soon'
            ? status == DueStatus.today || status == DueStatus.soon
            : status.name == filters.due);
    final resultMatches =
        filters.result == '*' ||
        (filters.result == 'empty'
            ? device.resultCode.isEmpty
            : filters.result == 'other'
            ? !['', 'OK', 'F'].contains(device.resultCode)
            : device.resultCode == filters.result);
    final monthMatches =
        filters.month.isEmpty ||
        (device.nextDay != null &&
            device.nextDay!.compareTo(reference) >= 0 &&
            device.nextDay!.monthKey == filters.month);
    return dueMatches &&
        resultMatches &&
        monthMatches &&
        tokens.every(device.searchText.contains);
  }).toList();
  filtered.sort((a, b) {
    var comparison = 0;
    if (filters.sortField == 'NextTest' || filters.sortField == 'LastTest') {
      final av = filters.sortField == 'NextTest' ? a.nextDay : a.lastDay;
      final bv = filters.sortField == 'NextTest' ? b.nextDay : b.lastDay;
      if (av == null && bv != null) return 1;
      if (av != null && bv == null) return -1;
      if (av != null && bv != null) comparison = av.compareTo(bv);
    } else {
      comparison = naturalCompare(
        filters.sortField == 'Location'
            ? a.location
            : a.value(filters.sortField),
        filters.sortField == 'Location'
            ? b.location
            : b.value(filters.sortField),
      );
    }
    if (comparison != 0) return filters.descending ? -comparison : comparison;
    final idOrder = naturalCompare(a.id, b.id);
    return idOrder != 0
        ? idOrder
        : naturalCompare(a.customerNumber, b.customerNumber);
  });
  return filtered;
}

class ForecastMonth {
  final CalendarDay start;
  final int count;
  const ForecastMonth(this.start, this.count);
}

List<ForecastMonth> forecast(
  List<DeviceRecord> scope,
  CalendarDay reference,
  int months,
) {
  final bucket = <String, int>{};
  final end = reference.monthStart(months);
  for (final device in scope) {
    final next = device.nextDay;
    if (next == null ||
        next.compareTo(reference) < 0 ||
        next.compareTo(end) >= 0)
      continue;
    bucket.update(next.monthKey, (count) => count + 1, ifAbsent: () => 1);
  }
  return List.generate(months, (index) {
    final start = reference.monthStart(index);
    return ForecastMonth(start, bucket[start.monthKey] ?? 0);
  });
}

class DashboardCounts {
  final Map<DueStatus, int> counts;
  final int total;
  final int failed;
  const DashboardCounts(this.counts, this.total, this.failed);
  factory DashboardCounts.fromDevices(
    List<DeviceRecord> scope,
    CalendarDay reference,
  ) {
    final counts = {for (final status in DueStatus.values) status: 0};
    var failed = 0;
    for (final device in scope) {
      counts.update(device.due(reference), (value) => value + 1);
      if (device.resultCode == 'F') failed++;
    }
    return DashboardCounts(counts, scope.length, failed);
  }
  int operator [](DueStatus status) => counts[status] ?? 0;
  int get soon => this[DueStatus.today] + this[DueStatus.soon];
}
