import 'package:flutter/material.dart';

class AppTheme {
  // V3 Navy/Gold primary
  static const Color primary = Color(0xFF111345);
  static const Color primaryDark = Color(0xFF0c112f);
  static const Color primaryLight = Color(0xFF1a1d66);
  static const Color accent = Color(0xFFD3A044);

  // V3 Neutral colors
  static const Color background = Color(0xFFF5F6FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0b1234);
  static const Color textSecondary = Color(0xFF73788d);
  static const Color textMuted = Color(0xFF73788d);
  static const Color border = Color(0xFFE7E9F1);

  // V3 Semantic
  static const Color success = Color(0xFF19a65a);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // V3 Gold
  static const Color gold = Color(0xFFD3A044);
  static const Color goldSoft = Color(0xFFFFF3DD);

  // V3 Card shadow
  static List<BoxShadow> get cardShadow => [
    const BoxShadow(
      color: Color(0x1A141846),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          );
        }
        return const TextStyle(
          color: Color(0xFF7A7F92),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: const Color(0xFF141638),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0c0f2e),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF141638),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1a1d50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF2a2d60), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1a1d50),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFF2a2d60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFF2a2d60)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF141638),
      indicatorColor: primary.withValues(alpha: 0.2),
    ),
  );
}
