import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFFF6B8B);
  static const Color primaryHover = Color(0xFFE84E75);
  static const Color primaryLight = Color(0xFFFFF0F2);
  static const Color secondary = Color(0xFF4A1525);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color lightText = Color(0xFF757E8A);
  static const Color bg = Color(0xFFFAFAFB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFF0E8EB);

  // Status Colors
  static const Color success = Color(0xFF2EC4B6);
  static const Color successLight = Color(0xFFE6F9F7);
  static const Color warning = Color(0xFFFFB627);
  static const Color warningLight = Color(0xFFFFF8E7);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color dangerLight = Color(0xFFFFEBEB);

  // Borders & Shadows
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusFull = 9999.0;

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: primary.withOpacity(0.05),
      offset: const Offset(0, 2),
      blurRadius: 8,
    )
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: primary.withOpacity(0.08),
      offset: const Offset(0, 8),
      blurRadius: 24,
    )
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: primary.withOpacity(0.12),
      offset: const Offset(0, 12),
      blurRadius: 32,
    )
  ];

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: cardBg,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
        displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
        titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
        bodyLarge: GoogleFonts.inter(fontSize: 14, color: darkText),
        bodyMedium: GoogleFonts.inter(fontSize: 12, color: lightText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkText),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),
    );
  }
}
