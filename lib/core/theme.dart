import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const accent = Color(0xFF21D4FD);
    const amber = Color(0xFFF9A826);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: amber,
        surface: Color(0xFF121A24),
      ),
    );

    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.sora(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.sora(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.sora(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.sora(fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.dmSans(),
      bodySmall: GoogleFonts.dmSans(),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xA5121A24),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xAA131B26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: accent.withValues(alpha: 0.2),
        backgroundColor: const Color(0xCC111925),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
