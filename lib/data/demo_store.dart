import '../domain/calendar_day.dart';
import '../domain/device.dart';
import 'platform_store.dart';

/// Synthetic data only. This mode is explicit and never mixes with a live file.
class DemoViewerStore implements ViewerStore {
  final CalendarDay reference;
  Map<String, Object?> settings = {};
  DemoViewerStore({CalendarDay? reference})
    : reference = reference ?? CalendarDay.today();

  @override
  Future<SourceConfiguration> configuration() async =>
      const SourceConfiguration(
        folder: 'Synthetic sample data',
        path: 'demo',
        configured: true,
        sourceId: 'demo',
      );
  @override
  Future<SourceConfiguration?> chooseFolder() async => configuration();
  @override
  Future<SourceConfiguration> savePath(String path) async => configuration();
  @override
  Future<Map<String, Object?>> loadSettings() async => settings;
  @override
  Future<void> saveSettings(Map<String, Object?> value) async {
    settings = Map.of(value);
  }

  @override
  Future<InspectionSnapshot> read() async {
    final customers = {'0001': 'Sample Company', '0002': 'Example Workshop'};
    final rows = List.generate(80, (index) {
      final offset = index % 9 == 0 ? -60 : index * 27 - 25;
      final date = DateTime.utc(
        reference.year,
        reference.month,
        reference.day + offset,
      );
      final next = CalendarDay(date.year, date.month, date.day).iso;
      final raw = <String, Object?>{
        'CustomerNumber': index < 65 ? '0001' : '0002',
        'IDNumber': '${1000000 + index}',
        'Location': [
          'Workshop',
          'Kitchen',
          'Room 2',
          'Room 10',
          '',
          'Building A / Floor 1',
        ][index % 6],
        'DeviceDescription': [
          'Power drill',
          'Fan',
          'Monitor',
          'Coffee machine',
          'Vacuum cleaner',
        ][index % 5],
        'Manufacturer': 'Sample Manufacturer',
        'Type': 'Model ${index % 4 + 1}',
        'LastTest': reference.monthStart(-12).iso,
        'NextTest': index % 17 == 0 ? '' : next,
        'TestResult': index % 23 == 0 ? 'F' : 'OK',
        'TestInterval': '12',
        'Class': 'I',
        'FactoryNumber': 'DEMO-$index',
        'Remark': 'Synthetic record. Do not use for real inspection decisions.',
      };
      return DeviceRecord(raw, customers);
    });
    return InspectionSnapshot(
      devices: rows,
      customers: customers,
      sourceLabel: 'DEMO · synthetic devices only',
      sourceId: 'demo',
      readAt: DateTime.now().toIso8601String(),
    );
  }
}
