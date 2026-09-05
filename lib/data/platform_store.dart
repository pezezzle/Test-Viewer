import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/device.dart';

class SourceConfiguration {
  final String folder;
  final String path;
  final bool configured;
  final String sourceId;
  const SourceConfiguration({
    this.folder = '',
    this.path = 'pcdrdata.sqlite3',
    this.configured = false,
    this.sourceId = '',
  });
  factory SourceConfiguration.fromJson(Map<String, Object?> value) =>
      SourceConfiguration(
        folder: value['folder']?.toString() ?? '',
        path: value['path']?.toString() ?? 'pcdrdata.sqlite3',
        configured: value['configured'] == true,
        sourceId: value['treeUri']?.toString() ?? '',
      );
  String get identity => '$sourceId/$path';
}

abstract class ViewerStore {
  Future<SourceConfiguration> configuration();
  Future<SourceConfiguration?> chooseFolder();
  Future<SourceConfiguration> savePath(String path);
  Future<InspectionSnapshot> read();
  Future<Map<String, Object?>> loadSettings();
  Future<void> saveSettings(Map<String, Object?> settings);
}

class PlatformViewerStore implements ViewerStore {
  static const channel = MethodChannel('com.pezezzle.testmasterviewer/data');

  Future<Map<String, Object?>> _map(String method, [Object? arguments]) async {
    final result = await channel.invokeMethod<Object?>(method, arguments);
    if (result is String)
      return Map<String, Object?>.from(jsonDecode(result) as Map);
    if (result is Map) return Map<String, Object?>.from(result);
    throw const FormatException('The platform returned an invalid response.');
  }

  @override
  Future<SourceConfiguration> configuration() async =>
      SourceConfiguration.fromJson(await _map('configuration'));
  @override
  Future<SourceConfiguration?> chooseFolder() async {
    final result = await channel.invokeMethod<String>('chooseFolder');
    return result == null
        ? null
        : SourceConfiguration.fromJson(
            Map<String, Object?>.from(jsonDecode(result) as Map),
          );
  }

  @override
  Future<SourceConfiguration> savePath(String path) async =>
      SourceConfiguration.fromJson(await _map('savePath', path));
  @override
  Future<InspectionSnapshot> read() async =>
      InspectionSnapshot.fromJson(await _map('readSnapshot'));
  @override
  Future<Map<String, Object?>> loadSettings() async => _map('loadSettings');
  @override
  Future<void> saveSettings(Map<String, Object?> settings) async {
    await channel.invokeMethod<void>('saveSettings', jsonEncode(settings));
  }
}
