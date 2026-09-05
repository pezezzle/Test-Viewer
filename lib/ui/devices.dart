import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/calendar_day.dart';
import '../domain/device.dart';
import '../domain/filters.dart';
import '../state/viewer_controller.dart';
import 'dialogs.dart';
import 'theme.dart';

const sortLabels = {
  'NextTest': 'Next inspection',
  'Location': 'Location',
  'IDNumber': 'Device number',
  'DeviceDescription': 'Description',
  'Manufacturer': 'Manufacturer',
  'LastTest': 'Last inspection',
  'TestResult': 'Result code',
};

class DevicesView extends StatefulWidget {
  final ViewerController controller;
  final VoidCallback onPageChanged;
  const DevicesView({
    super.key,
    required this.controller,
    required this.onPageChanged,
  });
  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  late final TextEditingController search;
  Timer? debounce;
  ViewerController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: controller.filters.search);
  }

  @override
  void didUpdateWidget(covariant DevicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (search.text != controller.filters.search &&
        !(debounce?.isActive ?? false))
      search.text = controller.filters.search;
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void changePage(int value) {
    controller.setPage(value);
    widget.onPageChanged();
  }

  @override
  Widget build(BuildContext context) {
    final filters = controller.filters;
    final rows = controller.pageRows;
    final all = controller.filtered;
    final dueOptions = {
      '*': 'All due dates',
      'overdue': 'Overdue',
      'today': filters.manualDate == null
          ? 'Due today'
          : 'Due on reference date',
      'soon': filters.manualDate == null
          ? 'Today through 30 days'
          : 'Reference date through 30 days',
      'medium': 'In 31–90 days',
      'later': 'More than 90 days',
      'missing': 'No valid due date',
    };
    const resultOptions = {
      '*': 'All results',
      'OK': 'OK',
      'F': 'F',
      'empty': 'No result',
      'other': 'Other codes',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final large = constraints.maxWidth >= 850;
                    final medium = constraints.maxWidth >= 500;
                    final searchWidth = large
                        ? constraints.maxWidth - 488
                        : constraints.maxWidth;
                    final filterWidth = large
                        ? 230.0
                        : medium
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: searchWidth,
                          child: TextField(
                            key: const ValueKey('device-search'),
                            controller: search,
                            decoration: InputDecoration(
                              labelText: 'Search devices',
                              hintText:
                                  'Device number, description, customer, location …',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        debounce?.cancel();
                                        search.clear();
                                        filters.search = '';
                                        controller.changed();
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                            onChanged: (value) {
                              debounce?.cancel();
                              debounce = Timer(
                                const Duration(milliseconds: 180),
                                () {
                                  filters.search = value;
                                  controller.changed();
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'due-${filters.due}-${filters.manualDate}',
                            ),
                            initialValue: filters.due,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Due date',
                            ),
                            items: dueOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                filters.due = value;
                                filters.month = '';
                                controller.changed();
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: filterWidth,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('result-${filters.result}'),
                            initialValue: filters.result,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Result code',
                            ),
                            items: resultOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                filters.result = value;
                                controller.changed();
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: ViewerColors.border),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  spacing: 22,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${formatCount(all.length)} of ${formatCount(controller.scope.length)} devices',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (filters.month.isNotEmpty)
                      InputChip(
                        label: Text(filters.month),
                        onDeleted: () {
                          filters.month = '';
                          controller.changed();
                        },
                      ),
                    SizedBox(
                      width: 245,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          '${filters.sortField}:${filters.descending}',
                        ),
                        initialValue:
                            '${filters.sortField}:${filters.descending ? 'desc' : 'asc'}',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sort order',
                        ),
                        items: [
                          for (final field in sortLabels.entries)
                            for (final direction in ['asc', 'desc'])
                              DropdownMenuItem(
                                value: '${field.key}:$direction',
                                child: Text(
                                  '${field.value} ${direction == 'asc' ? '↑' : '↓'}',
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            final parts = value.split(':');
                            filters.sortField = parts[0];
                            filters.descending = parts[1] == 'desc';
                            controller.changed();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 38,
                        color: ViewerColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No matching devices',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Change the search or reset the filters.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              if (rows.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 700
                      ? Column(
                          children: [
                            for (final row in rows) _deviceCard(context, row),
                          ],
                        )
                      : _deviceTable(context, rows, constraints.maxWidth),
                ),
              const Divider(height: 1, color: ViewerColors.border),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 165,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('page-size-${filters.pageSize}'),
                        initialValue: filters.pageSize,
                        decoration: const InputDecoration(
                          labelText: 'Entries per page',
                        ),
                        items: [
                          for (final value in pageSizes)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            filters.pageSize = value;
                            controller.changed();
                            widget.onPageChanged();
                          }
                        },
                      ),
                    ),
                    Text(
                      all.isEmpty
                          ? 'No results'
                          : '${controller.page * filters.pageSize + 1}–${controller.page * filters.pageSize + rows.length} · Page ${controller.page + 1} / ${controller.totalPages}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ViewerColors.muted,
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: controller.page > 0
                              ? () => changePage(controller.page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.page + 1 < controller.totalPages
                              ? () => changePage(controller.page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'Tap a device for details. Result and status codes remain unchanged. The entire page scrolls; there is no constrained vertical table area.',
            style: TextStyle(fontSize: 12, color: ViewerColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(BuildContext context, DeviceRecord device) {
    final status = device.due(controller.reference);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => showDeviceDetails(context, device, controller),
        child: Container(
          key: ValueKey('device-${device.identity}'),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ViewerColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      device.id.isEmpty ? '—' : device.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ViewerColors.brand,
                      ),
                    ),
                  ),
                  StatusBadge(
                    text: device.value('TestResult').trim().isEmpty
                        ? '—'
                        : device.value('TestResult'),
                    color: device.resultCode == 'F'
                        ? ViewerColors.overdue
                        : device.resultCode == 'OK'
                        ? ViewerColors.later
                        : ViewerColors.missing,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                device.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (device.value('Manufacturer').isNotEmpty ||
                  device.value('Type').isNotEmpty)
                Text(
                  [
                    device.value('Manufacturer'),
                    device.value('Type'),
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: const TextStyle(
                    color: ViewerColors.muted,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 17,
                    color: ViewerColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      locationLabel(device.location),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _smallDate(
                    'Last inspection',
                    displayDate(device.value('LastTest')),
                  ),
                  _smallDate(
                    'Next inspection',
                    displayDate(device.value('NextTest')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(
                    text: dueLabel(
                      status,
                      manual: controller.filters.manualDate != null,
                    ),
                    color: dueColor(status),
                  ),
                  Text(
                    device.daysLabel(
                      controller.reference,
                      manual: controller.filters.manualDate != null,
                    ),
                    style: const TextStyle(
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
    );
  }

  Widget _smallDate(String title, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 11, color: ViewerColors.muted),
      ),
      Text(value, style: const TextStyle(fontSize: 13)),
    ],
  );

  Widget _deviceTable(
    BuildContext context,
    List<DeviceRecord> rows,
    double width,
  ) {
    final fields = [
      'IDNumber',
      'DeviceDescription',
      'Location',
      'LastTest',
      'NextTest',
      '',
      'TestResult',
    ];
    final labels = [
      'Device no.',
      'Device',
      'Location',
      'Last inspection',
      'Next inspection',
      'Due date',
      'Result',
    ];
    final sortIndex = fields.indexOf(controller.filters.sortField);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width),
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 24,
          horizontalMargin: 18,
          headingRowColor: const WidgetStatePropertyAll(
            ViewerColors.background,
          ),
          dataRowMinHeight: 86,
          dataRowMaxHeight: 108,
          sortColumnIndex: sortIndex >= 0 ? sortIndex : null,
          sortAscending: !controller.filters.descending,
          columns: [
            for (var index = 0; index < fields.length; index++)
              DataColumn(
                label: Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onSort: fields[index].isEmpty
                    ? null
                    : (column, ascending) => controller.sortBy(fields[column]),
              ),
          ],
          rows: rows.map((device) {
            final status = device.due(controller.reference);
            return DataRow(
              key: ValueKey('device-${device.identity}'),
              onSelectChanged: (_) =>
                  showDeviceDetails(context, device, controller),
              cells: [
                DataCell(
                  Text(
                    device.id,
                    style: const TextStyle(
                      color: ViewerColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            device.value('Manufacturer'),
                            device.value('Type'),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ViewerColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 135,
                    child: Text(
                      locationLabel(device.location),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    displayDate(device.value('LastTest')),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    displayDate(device.value('NextTest')),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(
                        text: dueLabel(
                          status,
                          manual: controller.filters.manualDate != null,
                        ),
                        color: dueColor(status),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        device.daysLabel(
                          controller.reference,
                          manual: controller.filters.manualDate != null,
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          color: ViewerColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  StatusBadge(
                    text: device.value('TestResult').trim().isEmpty
                        ? '—'
                        : device.value('TestResult'),
                    color: device.resultCode == 'F'
                        ? ViewerColors.overdue
                        : device.resultCode == 'OK'
                        ? ViewerColors.later
                        : ViewerColors.missing,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
