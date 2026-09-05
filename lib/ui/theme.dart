import 'package:flutter/material.dart';

import '../domain/device.dart';

class ViewerColors {
  static const brand = Color(0xFF246BD4);
  static const brandSoft = Color(0xFFEAF2FF);
  static const background = Color(0xFFF4F7FB);
  static const ink = Color(0xFF202A38);
  static const muted = Color(0xFF657184);
  static const border = Color(0xFFDCE5F1);
  static const overdue = Color(0xFFB43448);
  static const soon = Color(0xFFB88737);
  static const medium = Color(0xFF477FC1);
  static const later = Color(0xFF438673);
  static const missing = Color(0xFF7C8797);
}

Color dueColor(DueStatus status) {
  switch (status) {
    case DueStatus.overdue:
      return ViewerColors.overdue;
    case DueStatus.today:
    case DueStatus.soon:
      return ViewerColors.soon;
    case DueStatus.medium:
      return ViewerColors.medium;
    case DueStatus.later:
      return ViewerColors.later;
    case DueStatus.missing:
      return ViewerColors.missing;
  }
}

ThemeData viewerTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: ViewerColors.brand, brightness: Brightness.light, surface: Colors.white),
  scaffoldBackgroundColor: ViewerColors.background,
  visualDensity: VisualDensity.standard,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ViewerColors.ink, fontSize: 14),
    bodySmall: TextStyle(color: ViewerColors.muted, fontSize: 12),
    titleLarge: TextStyle(color: ViewerColors.ink, fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: ViewerColors.ink, fontSize: 16, fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ViewerColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: ViewerColors.border),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ViewerColors.brand,
      foregroundColor: Colors.white,
      minimumSize: const Size(44, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ViewerColors.ink,
      minimumSize: const Size(44, 44),
      side: const BorderSide(color: ViewerColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ViewerColors.border),
      borderRadius: BorderRadius.circular(15),
    ),
    padding: padding,
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  const SectionTitle({super.key, required this.label, required this.title, this.subtitle = ''});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.7,
          fontWeight: FontWeight.w700,
          color: ViewerColors.brand,
        ),
      ),
      const SizedBox(height: 6),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    ),
  );
}
