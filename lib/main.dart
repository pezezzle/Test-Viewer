import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/demo_store.dart';
import 'data/platform_store.dart';
import 'state/viewer_controller.dart';
import 'ui/home.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestMasterApp());
}

class TestMasterApp extends StatefulWidget {
  final ViewerStore? store;
  final bool startInDemo;
  const TestMasterApp({super.key, this.store, this.startInDemo = false});
  @override
  State<TestMasterApp> createState() => _TestMasterAppState();
}

class _TestMasterAppState extends State<TestMasterApp> {
  late ViewerController controller;
  late bool demo;
  @override
  void initState() {
    super.initState();
    demo = widget.startInDemo || const bool.fromEnvironment('DEMO_MODE');
    _createController();
  }

  void _createController() {
    controller = ViewerController(store: demo ? DemoViewerStore() : widget.store ?? PlatformViewerStore(), demo: demo);
    unawaited(controller.initialize());
  }

  void _toggleDemo() {
    controller.dispose();
    setState(() {
      demo = !demo;
      _createController();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Test Viewer',
    debugShowCheckedModeBanner: false,
    theme: viewerTheme(),
    locale: const Locale('de', 'CH'),
    supportedLocales: const [Locale('de', 'CH'), Locale('de')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: HomeScreen(key: ValueKey(demo), controller: controller, onToggleDemo: _toggleDemo),
  );
}
