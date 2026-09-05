import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/calendar_day.dart';
import '../domain/device.dart';
import '../state/viewer_controller.dart';
import 'theme.dart';

// A popped dialog still builds during its exit animation. Keep its controllers
// alive until the route and its overlay entries have actually been removed.
Future<void> _showDialogUntilRemoved({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    builder: builder,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierColor: DialogTheme.of(context).barrierColor ?? Theme.of(context).dialogTheme.barrierColor ?? Colors.black54,
    barrierDismissible: barrierDismissible,
  );
  await navigator.push(route);
  await route.completed;
}

Future<void> showLocations(BuildContext context, ViewerController controller) async {
  final selected = Set<String>.of(controller.filters.locations);
  final search = TextEditingController();
  final counts = <String, int>{};
  for (final record in controller.snapshot?.devices ?? <DeviceRecord>[]) {
    counts.update(record.location, (count) => count + 1, ifAbsent: () => 1);
  }
  final values = {...controller.locations, ...selected}.toList()..sort(naturalCompare);
  await _showDialogUntilRemoved(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final tokens = searchTokens(search.text);
        final matches = values
            .where((location) => tokens.every((token) => normalizeSearch(locationLabel(location)).contains(token)))
            .toList();
        final selectionLabel = selected.isEmpty ? 'Alle Standorte' : '${selected.length} ausgewählt';
        final availableHeight = MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom - 48;
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          child: SizedBox(
            width: 510,
            height: math.min(620.0, math.max(200.0, availableHeight)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Standorte auswählen',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Schliessen',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    TextField(
                      key: const ValueKey('location-search'),
                      controller: search,
                      decoration: InputDecoration(
                        hintText: 'Standorte suchen …',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Suche leeren',
                                onPressed: () => setState(search.clear),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        TextButton(onPressed: () => setState(selected.clear), child: const Text('Alle Standorte')),
                        TextButton(
                          onPressed: matches.isEmpty ? null : () => setState(() => selected.addAll(matches)),
                          child: const Text('Treffer auswählen'),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${matches.length} Treffer · $selectionLabel',
                        style: const TextStyle(fontSize: 12, color: ViewerColors.muted),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: math.max(100.0, math.min(620.0, availableHeight) - 320),
                      child: matches.isEmpty
                          ? const Center(child: Text('Kein Standort gefunden.'))
                          : ListView.builder(
                              itemCount: matches.length,
                              itemBuilder: (context, index) {
                                final location = matches[index];
                                return CheckboxListTile(
                                  key: ValueKey('location-$location'),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(locationLabel(location)),
                                  subtitle: !counts.containsKey(location)
                                      ? const Text('Nicht im aktuellen Datenstand')
                                      : null,
                                  secondary: Text(formatCount(counts[location] ?? 0)),
                                  value: selected.contains(location),
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      selected.add(location);
                                    } else {
                                      selected.remove(location);
                                    }
                                  }),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.isEmpty ? 'Keine Einschränkung' : '${selected.length} Standorte',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            controller.setLocations(selected);
                            Navigator.pop(context);
                          },
                          child: const Text('Übernehmen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  search.dispose();
}

Future<void> showReferenceDate(BuildContext context, ViewerController controller) async {
  var selected = controller.reference;
  final input = TextEditingController(text: selected.iso);
  String? error;
  await _showDialogUntilRemoved(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Stichtag auswählen', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Schliessen',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Text(
                    'Fälligkeiten und Vorschauen werden für dieses Datum berechnet. Die Prüfdaten bleiben unverändert.',
                    style: TextStyle(color: ViewerColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    key: const ValueKey('reference-date-input'),
                    controller: input,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Datum (JJJJ-MM-TT)',
                      hintText: '2026-09-05',
                      errorText: error,
                    ),
                    onChanged: (value) {
                      final date = CalendarDay.parseReference(value);
                      if (date != null)
                        setState(() {
                          selected = date;
                          error = null;
                        });
                    },
                  ),
                  CalendarDatePicker(
                    key: ValueKey(selected.iso),
                    initialDate: selected.localDateTime,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(9999, 12, 31),
                    onDateChanged: (value) => setState(() {
                      selected = CalendarDay(value.year, value.month, value.day);
                      input.text = selected.iso;
                      error = null;
                    }),
                  ),
                  const Text(
                    'Ein manueller Stichtag bleibt gespeichert. „Heute · automatisch“ folgt wieder dem aktuellen Datum.',
                    style: TextStyle(fontSize: 12, color: ViewerColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          controller.setReference(null);
                          Navigator.pop(context);
                        },
                        child: const Text('Heute · automatisch'),
                      ),
                      FilledButton(
                        onPressed: () {
                          final date = CalendarDay.parseReference(input.text);
                          if (date == null) {
                            setState(() => error = 'Gib ein gültiges Datum zwischen 1900 und 9999 ein.');
                            return;
                          }
                          controller.setReference(date);
                          Navigator.pop(context);
                        },
                        child: const Text('Übernehmen'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  input.dispose();
}

Future<void> showSourceSettings(BuildContext context, ViewerController controller) async {
  controller.suspendAutoRefresh++;
  final path = TextEditingController(text: controller.config.path);
  var working = false;
  String? error;
  try {
    await _showDialogUntilRemoved(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: !working,
          child: Dialog(
            insetPadding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Datenbank einrichten',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Schliessen',
                            onPressed: working ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Wähle den Ordner mit deiner Prüfdatenbank. Der gewährte Zugriff wird für künftige Starts gespeichert.',
                        style: TextStyle(color: ViewerColors.muted),
                      ),
                      const SizedBox(height: 18),
                      const Text('Freigegebener Ordner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SelectableText(
                        controller.config.folder.isEmpty ? 'Noch kein Ordner ausgewählt' : controller.config.folder,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: working
                              ? null
                              : () async {
                                  setState(() {
                                    working = true;
                                    error = null;
                                  });
                                  try {
                                    await controller.chooseFolder();
                                  } catch (exception) {
                                    error = exception is PlatformException ? exception.message : exception.toString();
                                  }
                                  if (context.mounted) setState(() => working = false);
                                },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Ordner auswählen'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        key: const ValueKey('database-path'),
                        controller: path,
                        enabled: !working,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Dateiname oder relativer Pfad',
                          hintText: 'pcdrdata.sqlite3',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Beispiele: pcdrdata.sqlite3 oder Prüfungen/pcdrdata.sqlite3. Die Daten werden immer aus dem freigegebenen Ordner gelesen, nie aus einer dauerhaft importierten Kopie.',
                        style: TextStyle(fontSize: 12, color: ViewerColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ViewerColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Beende und speichere die Prüfung und öffne danach diesen Viewer. Falls eine Journal-Warnung erscheint, schliesse die Prüf-App vollständig und aktualisiere erneut. Journal-Dateien niemals löschen.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(error!, style: const TextStyle(color: ViewerColors.overdue)),
                        ),
                      if (working) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: working ? null : () => Navigator.pop(context),
                            child: const Text('Schliessen'),
                          ),
                          FilledButton(
                            onPressed: working || !controller.config.configured
                                ? null
                                : () async {
                                    setState(() {
                                      working = true;
                                      error = null;
                                    });
                                    try {
                                      await controller.savePathAndRefresh(path.text);
                                      if (!context.mounted) return;
                                      if (controller.error == null) {
                                        Navigator.pop(context);
                                        return;
                                      }
                                      error = controller.error;
                                    } catch (exception) {
                                      error = exception is PlatformException ? exception.message : exception.toString();
                                    }
                                    if (context.mounted) setState(() => working = false);
                                  },
                            child: const Text('Pfad speichern und laden'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nur Lesen · Kein Upload · Keine Cloud-Verbindung',
                        style: TextStyle(fontSize: 11, color: ViewerColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    path.dispose();
    controller.suspendAutoRefresh--;
  }
}

Future<void> showDeviceDetails(BuildContext context, DeviceRecord device, ViewerController controller) async {
  final labels = <String, String>{
    'CustomerNumber': 'Kundennummer',
    'IDNumber': 'Gerätenr.',
    'Location': 'Standort',
    'DeviceDescription': 'Bezeichnung',
    'Manufacturer': 'Hersteller',
    'Type': 'Typ',
    'FactoryNumber': 'Seriennummer',
    'Class': 'Schutzklasse',
    'Standard': 'Standard',
    'SubStandard': 'Zusätzliche Norm',
    'LastTest': 'Letzte Prüfung',
    'NextTest': 'Nächste Prüfung',
    'TestInterval': 'Prüfintervall (Originalwert)',
    'TestResult': 'Ergebniscode',
    'Status': 'Statuscode',
    'User1': 'Benutzerfeld 1',
    'User2': 'Benutzerfeld 2',
    'User3': 'Benutzerfeld 3',
    'Remark': 'Bemerkung',
  };
  final fields = <MapEntry<String, String>>[
    MapEntry('Kunde', device.customerName),
    ...labels.entries.map(
      (entry) => MapEntry(
        entry.value,
        entry.key == 'LastTest' || entry.key == 'NextTest'
            ? displayDate(device.value(entry.key))
            : entry.key == 'Location'
            ? locationLabel(device.location)
            : device.value(entry.key),
      ),
    ),
  ];
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SectionTitle(label: 'Gerät ${device.id}', title: device.description),
                    ),
                    IconButton(
                      tooltip: 'Schliessen',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    text: dueLabel(device.due(controller.reference), manual: controller.filters.manualDate != null),
                    color: dueColor(device.due(controller.reference)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  device.daysLabel(controller.reference, manual: controller.filters.manualDate != null),
                  style: const TextStyle(color: ViewerColors.muted),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 550 ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        for (final field in fields)
                          SizedBox(
                            width: field.key == 'Remark' ? constraints.maxWidth : width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(field.key, style: const TextStyle(fontSize: 12, color: ViewerColors.muted)),
                                const SizedBox(height: 4),
                                SelectableText(
                                  field.value.trim().isEmpty ? '—' : field.value,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Eindeutige Identität: Kundennummer + Gerätenr. · Nur Lesen, keine Bearbeitung',
                  style: TextStyle(fontSize: 11, color: ViewerColors.muted),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Schliessen')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
