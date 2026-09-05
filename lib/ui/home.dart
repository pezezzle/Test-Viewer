import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/calendar_day.dart';
import '../domain/device.dart';
import '../state/viewer_controller.dart';
import 'dashboard.dart';
import 'devices.dart';
import 'dialogs.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  final ViewerController controller;
  final VoidCallback onToggleDemo;
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onToggleDemo,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController scroll = ScrollController();
  final tableStart = GlobalKey();
  ViewerController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(controller.resume());
  }

  void jumpToDevices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = tableStart.currentContext;
      if (mounted && target != null)
        unawaited(
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 180),
          ),
        );
    });
  }

  Future<void> settings() async {
    if (!controller.demo) await showSourceSettings(context, controller);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      return PopScope(
        canPop: controller.tab == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) controller.selectTab(0);
        },
        child: Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: SingleChildScrollView(
                controller: scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    if (controller.busy)
                      const LinearProgressIndicator(minHeight: 3),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width < 600
                                ? 16
                                : 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (controller.demo)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: _notice(
                                    'DEMO MODE · synthetic data only',
                                    ViewerColors.medium,
                                    action: TextButton(
                                      onPressed: widget.onToggleDemo,
                                      child: const Text('Exit demo'),
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _tab(
                                      'Dashboard',
                                      0,
                                      Icons.space_dashboard_outlined,
                                    ),
                                  ),
                                  Expanded(
                                    child: _tab(
                                      'Devices',
                                      1,
                                      Icons.list_alt_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 1,
                                color: ViewerColors.border,
                              ),
                              const SizedBox(height: 20),
                              if (controller.snapshot != null)
                                _filterBar(context),
                              if (controller.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _notice(
                                    '${controller.error}${controller.stale ? '\nThe visible devices are from the last successful read.' : ''}',
                                    ViewerColors.overdue,
                                  ),
                                ),
                              if (controller.persistenceWarning != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _notice(
                                    controller.persistenceWarning!,
                                    ViewerColors.soon,
                                  ),
                                ),
                              if (controller.snapshot?.warnings.isNotEmpty ??
                                  false)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _notice(
                                    controller.snapshot!.warnings.join('\n'),
                                    ViewerColors.soon,
                                  ),
                                ),
                              if (!controller.initialized)
                                const Padding(
                                  padding: EdgeInsets.all(50),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              if (controller.initialized &&
                                  controller.snapshot == null)
                                _welcome(context),
                              if (controller.snapshot != null &&
                                  controller.tab == 0)
                                DashboardView(controller: controller),
                              if (controller.snapshot != null &&
                                  controller.tab == 1)
                                Container(
                                  key: tableStart,
                                  child: DevicesView(
                                    controller: controller,
                                    onPageChanged: jumpToDevices,
                                  ),
                                ),
                              const Divider(
                                height: 1,
                                color: ViewerColors.border,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: Wrap(
                                  spacing: 20,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Test Viewer · 2.0.0',
                                      style: TextStyle(
                                        color: ViewerColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Test-Master companion · Offline · Read only',
                                      style: TextStyle(
                                        color: ViewerColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _notice(String message, Color color, {Widget? action}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: TextStyle(fontSize: 13, color: color)),
        if (action != null)
          Align(alignment: Alignment.centerRight, child: action),
      ],
    ),
  );

  Widget _header(BuildContext context) {
    final data = controller.snapshot;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/branding/test_viewer_icon.png',
                key: const ValueKey('brand-logo'),
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.customerHeading,
                    key: const ValueKey('customer-heading'),
                    style: TextStyle(
                      fontSize: compact ? 20 : 23,
                      color: ViewerColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    controller.customerHeading == 'Test Viewer'
                        ? 'Test-Master companion'
                        : 'Test Viewer · Test-Master companion',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ViewerColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data?.sourceLabel ?? 'Connect the database from your inspection app.',
          style: TextStyle(
            fontSize: 12,
            color: controller.stale ? ViewerColors.overdue : ViewerColors.muted,
          ),
        ),
        if (data != null)
          Text(
            '${controller.stale ? 'STALE SNAPSHOT · ' : ''}Last read: ${_readLabel(data.readAt)}',
            style: TextStyle(
              fontSize: 12,
              color: controller.stale
                  ? ViewerColors.overdue
                  : ViewerColors.muted,
            ),
          ),
      ],
    );
    final actions = Wrap(
      spacing: compact ? 6 : 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          key: const ValueKey('reference-date-button'),
          onTap: () => showReferenceDate(context, controller),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.filters.manualDate == null
                      ? 'REFERENCE DATE · AUTO'
                      : 'REFERENCE DATE · MANUAL',
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    color: ViewerColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.reference.display,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.edit_calendar_outlined,
                      size: 16,
                      color: ViewerColors.brand,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: controller.demo || controller.busy ? null : settings,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 15),
          ),
          child: Text(
            'Database',
            style: TextStyle(fontSize: compact ? 12 : 13),
          ),
        ),
        FilledButton(
          onPressed: controller.busy
              ? null
              : () {
                  if (controller.config.configured) {
                    unawaited(controller.refresh());
                  } else {
                    unawaited(settings());
                  }
                },
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, size: 17),
              const SizedBox(width: 5),
              Text('Refresh', style: TextStyle(fontSize: compact ? 12 : 13)),
            ],
          ),
        ),
      ],
    );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ViewerColors.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 30,
        vertical: 18,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 900
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [brand, const SizedBox(height: 16), actions],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: brand),
                  const SizedBox(width: 25),
                  actions,
                ],
              ),
      ),
    );
  }

  String _readLabel(String value) {
    final time = RegExp(r'[T ](\d{2}:\d{2})').firstMatch(value)?.group(1);
    return '${displayDate(value)}${time == null ? '' : ', $time'}';
  }

  Widget _tab(String label, int value, IconData icon) => InkWell(
    onTap: () => controller.selectTab(value),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 3,
            color: controller.tab == value
                ? ViewerColors.brand
                : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: controller.tab == value
                ? ViewerColors.brand
                : ViewerColors.muted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: controller.tab == value
                    ? ViewerColors.brand
                    : ViewerColors.muted,
              ),
            ),
          ),
          if (value == 1 && controller.snapshot != null) ...[
            const SizedBox(width: 8),
            Text(
              formatCount(controller.scope.length),
              style: const TextStyle(fontSize: 11, color: ViewerColors.muted),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _filterBar(BuildContext context) {
    final selected = controller.filters.locations;
    final title = selected.isEmpty
        ? 'All locations'
        : selected.length == 1
        ? locationLabel(selected.first)
        : '${selected.length} locations selected';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 32
                  : 380,
            ),
            child: OutlinedButton(
              onPressed: () => showLocations(context, controller),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 10),
                  Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 10),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
          Text(
            '${formatCount(controller.scope.length)} devices in the selected scope',
            style: const TextStyle(fontSize: 12, color: ViewerColors.muted),
          ),
          TextButton(
            onPressed: controller.resetFilters,
            child: const Text('Reset filters', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _welcome(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 35),
    child: Panel(
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Icon(
            Icons.dashboard_customize_outlined,
            size: 48,
            color: ViewerColors.brand,
          ),
          const SizedBox(height: 18),
          Text(
            'Your devices. Your overview.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          const Text(
            'Choose the folder containing pcdrdata.sqlite3. The source is read again whenever the app opens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ViewerColors.muted),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: controller.busy ? null : settings,
            icon: const Icon(Icons.folder_open),
            label: const Text('Connect database'),
          ),
          const SizedBox(height: 8),
          if (!controller.demo)
            TextButton(
              onPressed: widget.onToggleDemo,
              child: const Text('Try with sample data'),
            ),
          const SizedBox(height: 14),
          const Text(
            'Local · Offline · Read only',
            style: TextStyle(fontSize: 12, color: ViewerColors.muted),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
