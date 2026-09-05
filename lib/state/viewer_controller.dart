import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/platform_store.dart';
import '../domain/calendar_day.dart';
import '../domain/device.dart';
import '../domain/filters.dart';

class ViewerController extends ChangeNotifier {
  final ViewerStore store;
  final DateTime Function() clock;
  final bool demo;
  ViewerFilters filters = ViewerFilters();
  SourceConfiguration config = const SourceConfiguration();
  InspectionSnapshot? snapshot;
  bool busy = false;
  bool initialized = false;
  bool stale = false;
  String? error;
  String? persistenceWarning;
  int tab = 0;
  int page = 0;
  int suspendAutoRefresh = 0;
  int _generation = 0;
  bool _disposed = false;
  CalendarDay? _lastDay;
  Timer? _dayTimer;
  Future<void> _saveQueue = Future<void>.value();
  String _lastSource = '';

  ViewerController({
    required this.store,
    DateTime Function()? clock,
    this.demo = false,
  }) : clock = clock ?? DateTime.now;
  CalendarDay get reference => filters.reference(clock());
  List<DeviceRecord> get scope =>
      scopeDevices(snapshot?.devices ?? [], filters.locations);
  List<DeviceRecord> get filtered =>
      filterDevices(snapshot?.devices ?? [], filters, reference);
  int get totalPages =>
      ((filtered.length + filters.pageSize - 1) ~/ filters.pageSize)
          .clamp(1, 1 << 30)
          .toInt();
  List<DeviceRecord> get pageRows {
    final rows = filtered;
    page = page
        .clamp(
          0,
          ((rows.length + filters.pageSize - 1) ~/ filters.pageSize - 1)
              .clamp(0, 1 << 30)
              .toInt(),
        )
        .toInt();
    return rows.skip(page * filters.pageSize).take(filters.pageSize).toList();
  }

  List<String> get locations {
    final values = (snapshot?.devices ?? [])
        .map((device) => device.location)
        .toSet()
        .toList();
    values.sort(
      (a, b) => a.isEmpty
          ? (b.isEmpty ? 0 : 1)
          : b.isEmpty
          ? -1
          : naturalCompare(a, b),
    );
    return values;
  }

  String get customerHeading {
    final data = snapshot;
    if (data == null) return 'Test Viewer';
    final records = scope;
    final numbers = (records.isEmpty ? data.devices : records)
        .map((device) => device.customerNumber)
        .toSet();
    if (numbers.isEmpty) numbers.addAll(data.customers.keys);
    return numbers.length == 1
        ? DeviceRecord.resolveCustomer(numbers.first, data.customers)
        : numbers.length > 1
        ? '${formatCount(numbers.length)} customers'
        : 'Test Viewer';
  }

  Future<void> initialize() async {
    try {
      final saved = await store.loadSettings();
      filters = ViewerFilters.fromJson(saved);
      _lastSource = saved['sourceIdentity']?.toString() ?? '';
      tab = saved['tab'] == 'devices' ? 1 : 0;
      config = await store.configuration();
      if (_disposed) return;
      _resetForChangedSource();
    } catch (exception) {
      error = _message(exception);
    }
    if (_disposed) return;
    initialized = true;
    _lastDay = reference;
    _dayTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => synchronizeDay(),
    );
    _notify();
    if (config.configured) await refresh();
  }

  void synchronizeDay() {
    final current = reference;
    if (current == _lastDay) return;
    _lastDay = current;
    filters.month = '';
    page = 0;
    changed();
  }

  Future<void> resume() async {
    synchronizeDay();
    if (initialized && suspendAutoRefresh == 0 && config.configured && !busy)
      await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || busy || !config.configured) return;
    final token = ++_generation;
    busy = true;
    error = null;
    synchronizeDay();
    _notify();
    try {
      final loaded = await store.read();
      if (_disposed || token != _generation) return;
      snapshot = loaded;
      stale = false;
      page = 0;
      _lastSource = config.identity;
      _persist();
    } catch (exception) {
      if (_disposed || token != _generation) return;
      error = _message(exception);
      stale = snapshot != null;
    } finally {
      if (!_disposed && token == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> chooseFolder() async {
    suspendAutoRefresh++;
    try {
      final selected = await store.chooseFolder();
      if (_disposed || selected == null) return false;
      config = selected;
      _resetForChangedSource();
      _notify();
      return true;
    } finally {
      suspendAutoRefresh--;
    }
  }

  Future<void> savePathAndRefresh(String value) async {
    config = await store.savePath(value);
    if (_disposed) return;
    _resetForChangedSource();
    _notify();
    await refresh();
  }

  void _resetForChangedSource() {
    if (_lastSource.isNotEmpty && _lastSource != config.identity) {
      _generation++;
      busy = false;
      snapshot = null;
      stale = false;
      error = null;
      page = 0;
      filters.clearSearchScope();
    }
    _lastSource = config.identity;
  }

  void changed({bool resetPage = true}) {
    if (resetPage) page = 0;
    _persist();
    _notify();
  }

  void selectTab(int value) {
    tab = value;
    changed(resetPage: false);
  }

  void setReference(CalendarDay? value) {
    filters.manualDate = value;
    filters.month = '';
    _lastDay = reference;
    changed();
  }

  void setLocations(Set<String> value) {
    filters.locations = Set.of(value);
    changed();
  }

  void resetFilters() {
    filters.clearSearchScope();
    changed();
  }

  void openFiltered({
    String due = '*',
    String result = '*',
    String? location,
    String month = '',
  }) {
    filters.search = '';
    filters.due = due;
    filters.result = result;
    filters.month = month;
    if (location != null) filters.locations = {location};
    tab = 1;
    changed();
  }

  void sortBy(String field) {
    if (!sortFields.contains(field)) return;
    filters.descending = filters.sortField == field
        ? !filters.descending
        : false;
    filters.sortField = field;
    changed();
  }

  void setPage(int value) {
    page = value.clamp(0, totalPages - 1).toInt();
    _notify();
  }

  void _persist() {
    final value = {
      ...filters.toJson(),
      'tab': tab == 1 ? 'devices' : 'dashboard',
      'sourceIdentity': config.identity,
    };
    _saveQueue = _saveQueue.then((_) => store.saveSettings(value)).catchError((
      Object exception,
    ) {
      if (!_disposed) {
        persistenceWarning =
            'The settings could not be saved: ${_message(exception)}';
        _notify();
      }
    });
  }

  Future<void> flushSettings() => _saveQueue;
  String _message(Object exception) => exception is PlatformException
      ? exception.message ?? 'Database access failed.'
      : exception is MissingPluginException
      ? 'File access is available only in Android or iOS builds.'
      : exception.toString();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _dayTimer?.cancel();
    super.dispose();
  }
}
