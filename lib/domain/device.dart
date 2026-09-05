import 'calendar_day.dart';

String normalizeSearch(String value) {
  const replacements = {
    'ä': 'a',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'ö': 'o',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ü': 'u',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ç': 'c',
    'ñ': 'n',
    'ß': 'ss',
  };
  return value
      .toLowerCase()
      .split('')
      .map((character) => replacements[character] ?? character)
      .join()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}

List<String> searchTokens(String query) => normalizeSearch(
  query,
).split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
String locationLabel(String location) =>
    location.isEmpty ? 'Ohne Standort' : location;

/// Numeric-aware ordering keeps room 2 before room 10 without losing ID zeros.
int naturalCompare(String left, String right) {
  final a = RegExp(
    r'\d+|\D+',
  ).allMatches(normalizeSearch(left)).map((match) => match.group(0)!).toList();
  final b = RegExp(
    r'\d+|\D+',
  ).allMatches(normalizeSearch(right)).map((match) => match.group(0)!).toList();
  for (var index = 0; index < a.length && index < b.length; index++) {
    final an = BigInt.tryParse(a[index]);
    final bn = BigInt.tryParse(b[index]);
    final comparison = an != null && bn != null
        ? an.compareTo(bn)
        : a[index].compareTo(b[index]);
    if (comparison != 0) return comparison;
  }
  return a.length.compareTo(b.length);
}

enum DueStatus { overdue, today, soon, medium, later, missing }

String dueLabel(DueStatus status, {bool manual = false}) {
  switch (status) {
    case DueStatus.overdue:
      return 'Überfällig';
    case DueStatus.today:
      return manual ? 'Am Stichtag fällig' : 'Heute fällig';
    case DueStatus.soon:
      return 'In 1–30 Tagen';
    case DueStatus.medium:
      return 'In 31–90 Tagen';
    case DueStatus.later:
      return 'Später';
    case DueStatus.missing:
      return 'Ohne gültigen Termin';
  }
}

class DeviceRecord {
  final Map<String, String> fields;
  final String customerName;
  late final CalendarDay? nextDay = CalendarDay.parse(value('NextTest'));
  late final CalendarDay? lastDay = CalendarDay.parse(value('LastTest'));
  late final String searchText = normalizeSearch(
    [...fields.values, customerName].join(' '),
  );

  DeviceRecord(Map<String, Object?> raw, Map<String, String> customers)
    : fields = Map.unmodifiable(
        raw.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      ),
      customerName = resolveCustomer(
        raw['CustomerNumber']?.toString() ?? '',
        customers,
      );

  static String resolveCustomer(String number, Map<String, String> customers) {
    final name = customers[number]?.trim() ?? '';
    return name.isNotEmpty
        ? name
        : number.trim().isNotEmpty
        ? 'Kunde ${number.trim()}'
        : 'Kunde nicht angegeben';
  }

  String value(String key) => fields[key] ?? '';
  String get id => value('IDNumber');
  String get customerNumber => value('CustomerNumber');
  String get location => value('Location').trim();
  String get description => value('DeviceDescription').trim().isEmpty
      ? 'Ohne Bezeichnung'
      : value('DeviceDescription');
  String get resultCode => value('TestResult').trim().toUpperCase();
  String get identity => '${customerNumber.length}:$customerNumber$id';

  DueStatus due(CalendarDay reference) {
    final next = nextDay;
    if (next == null) return DueStatus.missing;
    final days = next.difference(reference);
    if (days < 0) return DueStatus.overdue;
    if (days == 0) return DueStatus.today;
    if (days <= 30) return DueStatus.soon;
    if (days <= 90) return DueStatus.medium;
    return DueStatus.later;
  }

  String daysLabel(CalendarDay reference, {bool manual = false}) {
    final next = nextDay;
    if (next == null)
      return value('NextTest').trim().isEmpty
          ? 'Kein Datum hinterlegt'
          : 'Ungültiger Datumswert';
    final days = next.difference(reference);
    if (days == 0) return manual ? 'Am Stichtag' : 'Am heutigen Tag';
    return days < 0
        ? '${formatCount(-days)} Tage überfällig'
        : 'In ${formatCount(days)} Tagen';
  }
}

class InspectionSnapshot {
  final List<DeviceRecord> devices;
  final Map<String, String> customers;
  final String sourceLabel;
  final String sourceId;
  final String readAt;
  final List<String> warnings;

  const InspectionSnapshot({
    required this.devices,
    required this.customers,
    required this.sourceLabel,
    required this.sourceId,
    required this.readAt,
    this.warnings = const [],
  });

  factory InspectionSnapshot.fromJson(Map<String, Object?> json) {
    final customers = <String, String>{};
    for (final item in (json['customers'] as List<Object?>? ?? [])) {
      if (item is Map)
        customers[item['CustomerNumber']?.toString() ?? ''] =
            item['Name']?.toString().trim() ?? '';
    }
    final devices = <DeviceRecord>[];
    for (final item in (json['devices'] as List<Object?>? ?? [])) {
      if (item is Map)
        devices.add(DeviceRecord(Map<String, Object?>.from(item), customers));
    }
    return InspectionSnapshot(
      devices: List.unmodifiable(devices),
      customers: Map.unmodifiable(customers),
      sourceLabel: json['sourceLabel']?.toString() ?? '',
      sourceId:
          json['sourceUri']?.toString() ??
          json['sourceLabel']?.toString() ??
          '',
      readAt: json['readAt']?.toString() ?? '',
      warnings: (json['warnings'] as List<Object?>? ?? [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}
