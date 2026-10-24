import 'package:flutter/material.dart';

/// Accent colors used across the app, with lighter variants for dark mode.
class AppPalette {
  const AppPalette._({
    required this.blue,
    required this.green,
    required this.orange,
    required this.purple,
    required this.teal,
    required this.coral,
    required this.isDark,
  });

  final Color blue;
  final Color green;
  final Color orange;
  final Color purple;
  final Color teal;
  final Color coral;
  final bool isDark;

  static const _light = AppPalette._(
    blue: Color(0xFF2F6FDE),
    green: Color(0xFF2E9E5B),
    orange: Color(0xFFE08A2E),
    purple: Color(0xFF7B5CD6),
    teal: Color(0xFF1E9AA8),
    coral: Color(0xFFD9534F),
    isDark: false,
  );

  static const _dark = AppPalette._(
    blue: Color(0xFF8AB4FF),
    green: Color(0xFF69C98B),
    orange: Color(0xFFF2B872),
    purple: Color(0xFFB9A4FF),
    teal: Color(0xFF6FD3DE),
    coral: Color(0xFFFF8A80),
    isDark: true,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Card background tinted with [color].
  Color tint(Color color) => color.withValues(alpha: isDark ? 0.16 : 0.10);

  /// Background of an icon badge accented with [color].
  Color badge(Color color) => color.withValues(alpha: isDark ? 0.26 : 0.16);

  Color forActionType(String actionType) {
    final type = actionType.toLowerCase();
    if (type.contains('candidature')) return green;
    if (type.contains('entretien')) return orange;
    if (type.contains('cv')) return purple;
    if (type.contains('message')) return teal;
    if (type.contains('formation')) return coral;
    return blue;
  }

  static IconData iconForActionType(String actionType) {
    final type = actionType.toLowerCase();
    if (type.contains('candidature')) return Icons.send_outlined;
    if (type.contains('entretien')) return Icons.groups_outlined;
    if (type.contains('cv')) return Icons.badge_outlined;
    if (type.contains('message')) return Icons.mail_outline;
    if (type.contains('formation')) return Icons.school_outlined;
    return Icons.search;
  }
}
