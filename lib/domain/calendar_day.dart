/// A calendar date independent of timezone and daylight-saving transitions.
class CalendarDay implements Comparable<CalendarDay> {
  final int year;
  final int month;
  final int day;

  const CalendarDay(this.year, this.month, this.day);

  factory CalendarDay.today([DateTime? now]) {
    final local = now ?? DateTime.now();
    return CalendarDay(local.year, local.month, local.day);
  }

  static CalendarDay? parse(Object? value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|[ T])').firstMatch(value?.toString() ?? '');
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) return null;
    final checked = DateTime.utc(year, month, day);
    if (checked.year != year || checked.month != month || checked.day != day) return null;
    return CalendarDay(year, month, day);
  }

  static CalendarDay? parseReference(Object? value) {
    final text = value?.toString() ?? '';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = parse(text);
    return date != null && date.year >= 1900 ? date : null;
  }

  int get ordinal => DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  DateTime get localDateTime => DateTime(year, month, day);
  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  String get monthKey => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  String get display =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.${year.toString().padLeft(4, '0')}';
  int difference(CalendarDay other) => ordinal - other.ordinal;

  CalendarDay monthStart(int offset) {
    final date = DateTime.utc(year, month + offset, 1);
    return CalendarDay(date.year, date.month, 1);
  }

  @override
  int compareTo(CalendarDay other) => ordinal.compareTo(other.ordinal);
  @override
  bool operator ==(Object other) =>
      other is CalendarDay && other.year == year && other.month == month && other.day == day;
  @override
  int get hashCode => Object.hash(year, month, day);
  @override
  String toString() => iso;
}

const monthNames = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
String monthLabel(CalendarDay value) => '${monthNames[value.month - 1]} ${value.year}';
String displayDate(String value) => CalendarDay.parse(value)?.display ?? (value.trim().isEmpty ? '—' : value);
String formatCount(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '’');
