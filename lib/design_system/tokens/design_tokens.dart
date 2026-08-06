import 'package:flutter/material.dart';

class AppColors {
  // V3 Navy/Gold primary
  static const Color primary = Color(0xFF111345);
  static const Color primaryDark = Color(0xFF0c112f);
  static const Color primaryLight = Color(0xFF1a1d66);
  static const Color primaryContainer = Color(0xFFf2f3fa);

  // V3 Gold accent
  static const Color accent = Color(0xFFD3A044);
  static const Color accentLight = Color(0xFFe9c476);
  static const Color accentDark = Color(0xFFb9822d);

  // V3 Gold soft
  static const Color gold = Color(0xFFD3A044);
  static const Color goldSoft = Color(0xFFFFF3DD);

  // V3 Navy aliases
  static const Color navy = Color(0xFF111345);
  static const Color navy2 = Color(0xFF1a1d66);

  // Semantic colors
  static const Color success = Color(0xFF19a65a);
  static const Color successLight = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFe6f7ee);
  static const Color greenSoft = Color(0xFFe6f7ee);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Experience-specific colors
  static const Color experienceRestaurant = Color(0xFFF97316);
  static const Color experienceRetail = Color(0xFFEC4899);
  static const Color experienceAppointment = Color(0xFF8B5CF6);
  static const Color experienceStay = Color(0xFF3B82F6);
  static const Color experienceTurf = Color(0xFF14B8A6);
  static const Color experienceTaxi = Color(0xFFF97316);
  static const Color experienceSharedTransport = Color(0xFF06B6D4);
  static const Color experienceVehicleRental = Color(0xFF6366F1);
  static const Color experienceGoodsTransport = Color(0xFF64748B);
  static const Color experienceSeatEvent = Color(0xFFF43F5E);

  // V3 Neutral colors - Light theme
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6FB);
  static const Color surfaceVariant = Color(0xFFF0F2F8);
  static const Color outline = Color(0xFFE7E9F1);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  static const Color textPrimary = Color(0xFF0b1234);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF73788d);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0b1234);
  static const Color onSurfaceVariant = Color(0xFF475569);

  // V3 muted
  static const Color muted = Color(0xFF73788d);

  // V3 soft (icon tiles, action grid)
  static const Color soft = Color(0xFFf0f2f8);

  // V3 line (borders)
  static const Color line = Color(0xFFe7e9f1);

  // V3 card
  static const Color card = Color(0xFFFFFFFF);

  // Neutral colors - Dark theme (navy-tinted)
  static const Color darkSurface = Color(0xFF141638);
  static const Color darkBackground = Color(0xFF0c0f2e);
  static const Color darkSurfaceVariant = Color(0xFF1a1d50);
  static const Color darkOutline = Color(0xFF2a2d60);
  static const Color darkOutlineVariant = Color(0xFF3a3d70);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);
  static const Color darkTextInverse = Color(0xFF0b1234);

  static const Color darkOnPrimary = Color(0xFF0c0f2e);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFFCBD5E1);

  // Shadow
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
}

class AppTypography {
  static const String fontFamily = 'Inter';

  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(vertical: lg);
}

class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double card = 22;
  static const double hero = 25;
  static const double detailCard = 28;
  static const double sheet = 28;
  static const double pill = 999;
  static const double full = 9999;
}

class AppElevation {
  static const double none = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;

  // V3 card shadow
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A141846),
    blurRadius: 40,
    offset: Offset(0, 16),
  );

  static List<BoxShadow> shadowLevel1(Color shadowColor) => [
    BoxShadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> shadowLevel2(Color shadowColor) => [
    BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
    BoxShadow(color: shadowColor, blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> shadowLevel3(Color shadowColor) => [
    BoxShadow(color: shadowColor, blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2)),
  ];
}

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 500);

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve decelerated = Curves.decelerate;
}
