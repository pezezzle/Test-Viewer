import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/calendar_day.dart';
import '../domain/device.dart';
import '../domain/filters.dart';
import '../state/viewer_controller.dart';
import 'theme.dart';

class DashboardView extends StatelessWidget {
  final ViewerController controller;
  const DashboardView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scope = controller.scope;
    final counts = DashboardCounts.fromDevices(scope, controller.reference);
    final manual = controller.filters.manualDate != null;
    final cards =
        <
          ({
            String title,
            int count,
            String subtitle,
            Color color,
            VoidCallback action,
          })
        >[
          (
            title: 'Devices in inventory',
            count: counts.total,
            subtitle: 'In the selected scope',
            color: ViewerColors.brand,
            action: () => controller.openFiltered(),
          ),
          (
            title: 'Overdue',
            count: counts[DueStatus.overdue],
            subtitle: manual
                ? 'Inspection due before the reference date'
                : 'Inspection due before today',
            color: ViewerColors.overdue,
            action: () => controller.openFiltered(due: 'overdue'),
          ),
          (
            title: 'Due within 30 days',
            count: counts.soon,
            subtitle: manual
                ? 'Including the reference date'
                : 'Including today',
            color: ViewerColors.soon,
            action: () => controller.openFiltered(due: 'soon'),
          ),
          (
            title: 'Due in 31–90 days',
            count: counts[DueStatus.medium],
            subtitle: 'Next planning period',
            color: ViewerColors.medium,
            action: () => controller.openFiltered(due: 'medium'),
          ),
          (
            title: 'No valid due date',
            count: counts[DueStatus.missing],
            subtitle: 'Check in the inspection app',
            color: ViewerColors.missing,
            action: () => controller.openFiltered(due: 'missing'),
          ),
          (
            title: 'Result code F',
            count: counts.failed,
            subtitle: 'Current device record',
            color: counts.failed > 0
                ? ViewerColors.overdue
                : ViewerColors.brand,
            action: () => controller.openFiltered(result: 'F'),
          ),
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1150
                ? 6
                : constraints.maxWidth >= 650
                ? 3
                : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: card.action,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 158),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: ViewerColors.border),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ViewerColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                formatCount(card.count),
                                style: TextStyle(
                                  fontSize: 34,
                                  color: card.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${card.subtitle} ↗',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ViewerColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final due = _duePanel(context, counts, manual);
            final locations = _locationPanel(context, scope);
            if (constraints.maxWidth < 850)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [due, const SizedBox(height: 18), locations],
              );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: due),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: locations),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _forecastPanel(context, scope),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'Due dates come from “NextTest”. Missing dates are not estimated from the inspection interval. A future due date does not indicate operational safety.',
            style: TextStyle(fontSize: 12, color: ViewerColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _duePanel(BuildContext context, DashboardCounts counts, bool manual) {
    final parts = <({String label, int value, Color color, String filter})>[
      (
        label: 'Overdue',
        value: counts[DueStatus.overdue],
        color: ViewerColors.overdue,
        filter: 'overdue',
      ),
      (
        label: manual ? 'Reference date to 30 days' : 'Today to 30 days',
        value: counts.soon,
        color: ViewerColors.soon,
        filter: 'soon',
      ),
      (
        label: '31–90 days',
        value: counts[DueStatus.medium],
        color: ViewerColors.medium,
        filter: 'medium',
      ),
      (
        label: 'More than 90 days',
        value: counts[DueStatus.later],
        color: ViewerColors.later,
        filter: 'later',
      ),
      (
        label: 'No valid due date',
        value: counts[DueStatus.missing],
        color: ViewerColors.missing,
        filter: 'missing',
      ),
    ];
    final accessibleSummary = parts
        .map((part) => '${part.label} ${part.value}')
        .join(', ');
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            label: 'Inspection dates',
            title: 'Due dates',
            subtitle: 'Distribution of upcoming inspections',
          ),
          const SizedBox(height: 20),
          Center(
            child: Semantics(
              label: 'Due dates: $accessibleSummary',
              child: SizedBox(
                width: 175,
                height: 175,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DonutPainter(
                          values: parts.map((part) => part.value).toList(),
                          colors: parts.map((part) => part.color).toList(),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCount(counts.total),
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Total devices',
                          style: TextStyle(
                            fontSize: 11,
                            color: ViewerColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final part in parts)
            InkWell(
              onTap: () => controller.openFiltered(due: part.filter),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: part.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        part.label,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      formatCount(part.value),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: ViewerColors.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationPanel(BuildContext context, List<DeviceRecord> scope) {
    final counts = <String, int>{};
    for (final device in scope) {
      if (device.due(controller.reference) == DueStatus.overdue)
        counts.update(device.location, (count) => count + 1, ifAbsent: () => 1);
    }
    final locations = counts.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : naturalCompare(a.key, b.key);
      });
    final top = locations.take(8).toList();
    final maximum = top.isEmpty ? 1 : top.first.value;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            label: 'Priorities',
            title: 'Overdue devices by location',
            subtitle: 'Eight largest backlogs · tap to filter',
          ),
          const SizedBox(height: 20),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 55),
              child: Text(
                'No overdue devices in this scope.',
                style: TextStyle(color: ViewerColors.muted),
              ),
            ),
          for (final entry in top)
            InkWell(
              onTap: () =>
                  controller.openFiltered(due: 'overdue', location: entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            locationLabel(entry.key),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatCount(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / maximum,
                        minHeight: 9,
                        backgroundColor: ViewerColors.brandSoft,
                        color: ViewerColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _forecastPanel(BuildContext context, List<DeviceRecord> scope) {
    final months = forecast(
      scope,
      controller.reference,
      controller.filters.horizonMonths,
    );
    final maxCount = months.fold<int>(
      1,
      (current, month) => math.max(current, month.count),
    );
    final startLabel = controller.filters.manualDate == null
        ? 'today'
        : 'reference date ${controller.reference.display}';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 22,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SectionTitle(
                label: 'Forecast',
                title:
                    'Due dates for the next ${controller.filters.horizonMonths} months',
                subtitle:
                    'Starting $startLabel; overdue devices are not counted again.',
              ),
              SizedBox(
                width: 155,
                child: DropdownButtonFormField<int>(
                  key: ValueKey(controller.filters.horizonMonths),
                  isExpanded: true,
                  initialValue: controller.filters.horizonMonths,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: [
                    for (final value in horizons)
                      DropdownMenuItem(
                        value: value,
                        child: Text('$value months'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.filters.horizonMonths = value;
                      controller.changed(resetPage: false);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${monthLabel(months.first.start)} – ${monthLabel(months.last.start)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a month to view devices · swipe horizontally if needed',
            style: TextStyle(fontSize: 11, color: ViewerColors.muted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = math.max(
                46.0,
                constraints.maxWidth / months.length,
              );
              return SingleChildScrollView(
                key: ValueKey(
                  'forecast-${controller.filters.horizonMonths}-${controller.reference.iso}',
                ),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final month in months)
                      Semantics(
                        button: true,
                        label:
                            '${monthLabel(month.start)}: ${month.count} devices',
                        child: InkWell(
                          onTap: () => controller.openFiltered(
                            month: month.start.monthKey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: barWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 6,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    month.count == 0
                                        ? '–'
                                        : formatCount(month.count),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  SizedBox(
                                    height: 140,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: math.max(
                                          2.0,
                                          month.count / maxCount * 140.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ViewerColors.brand,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${monthNames[month.start.month - 1]}\n${month.start.year}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: ViewerColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  DonutPainter({required this.values, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = rect.deflate(15);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    paint.color = ViewerColors.brandSoft;
    canvas.drawOval(circle, paint);
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final angle = values[index] / total * math.pi * 2;
      paint.color = colors[index];
      canvas.drawArc(circle, start, angle, false, paint);
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => true;
}
