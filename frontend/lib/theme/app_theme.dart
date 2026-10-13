import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// DigiGuide Master Design System & Theme Engine
/// Blends Apple Human Interface Guidelines with Google Material 3 Expressive.
/// Enhanced with True OLED Pitch Black luxury dark mode.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // COLOR TOKENS: Coral & Amber Sunset Spectrum (Primary Brand)
  // ---------------------------------------------------------------------------
  static const Color coral50 = Color(0xFFFFF1F2);
  static const Color coral100 = Color(0xFFFFE4E6);
  static const Color coral200 = Color(0xFFFECDD3);
  static const Color coral300 = Color(0xFFFDA4AF);
  static const Color coral400 = Color(0xFFFB7185);
  static const Color coral500 = Color(0xFFFF5E48); // Vibrant Apple-tuned Coral
  static const Color coral600 = Color(0xFFE54532);
  static const Color coral700 = Color(0xFFC53020);

  // Warm Amber Glow & Sunlight Accents
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // ---------------------------------------------------------------------------
  // COLOR TOKENS: True Pitch Black OLED & Neutral Titanium Spectrum
  // ---------------------------------------------------------------------------
  static const Color obsidian950 = Color(0xFF000000); // Pure OLED Pitch Black
  static const Color obsidian900 = Color(0xFF08080A); // Deep Canvas
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate850 = Color(0xFF121214);    // Luxury Charcoal Elevated Card
  static const Color slate800 = Color(0xFF18181B);    // Neutral Dark Card Base
  static const Color slate700 = Color(0xFF27272A);
  static const Color slate600 = Color(0xFF3F3F46);
  static const Color slate500 = Color(0xFF71717A);
  static const Color slate400 = Color(0xFFA1A1AA);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF4F4F5);
  static const Color slate50 = Color(0xFFFAFAFA);

  // Light Canvas Surface
  static const Color surfacePureWhite = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);

  // ---------------------------------------------------------------------------
  // SEMANTIC & GLANCE ACCENTS (Live status, weather, audio, radar)
  // ---------------------------------------------------------------------------
  static const Color emeraldLive = Color(0xFF10B981);  // Proximity radar & open status
  static const Color skyAzure = Color(0xFF38BDF8);     // Weather & audio guides
  static const Color violetAI = Color(0xFF8B5CF6);     // Vision AI & ML models

  // ---------------------------------------------------------------------------
  // TYPOGRAPHY SYSTEM: Plus Jakarta Sans / SF Pro Geometry
  // ---------------------------------------------------------------------------
  static TextTheme _buildTextTheme({required bool isDark}) {
    final baseColor = isDark ? Colors.white : slate900;
    final secondaryColor = isDark ? const Color(0xFFA1A1AA) : slate600;

    final textTheme = TextTheme(
      // Display: Bold hero headlines
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.15,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
        color: baseColor,
      ),

      // Headlines: Section anchors
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.25,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
        color: baseColor,
      ),

      // Titles: Cards and List headers
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: secondaryColor,
      ),

      // Body: Readable descriptions and facts
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
        color: secondaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.45,
        color: secondaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xFF71717A) : slate400,
      ),

      // Labels: Pills, tags, captions
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFFA1A1AA) : slate500,
      ),
    );

    return GoogleFonts.plusJakartaSansTextTheme(textTheme);
  }

  // ---------------------------------------------------------------------------
  // LIGHT THEME (Clean, Crisp, Apple Daylight Aesthetics)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: coral500,
      colorScheme: ColorScheme.light(
        primary: coral500,
        onPrimary: Colors.white,
        primaryContainer: coral100,
        onPrimaryContainer: coral700,
        secondary: amber500,
        onSecondary: Colors.white,
        surface: surfacePureWhite,
        onSurface: slate900,
        surfaceContainerHighest: slate100,
        outline: slate300,
        outlineVariant: const Color(0xFFE2E8F0),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        iconTheme: const IconThemeData(color: slate800),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: slate900,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfacePureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral500,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slate800,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfacePureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: coral500, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: slate400),
        prefixIconColor: slate400,
      ),
      dividerColor: const Color(0xFFF1F5F9),
    );
  }

  // ---------------------------------------------------------------------------
  // DARK THEME: TRUE OLED PITCH BLACK LUXURY AESTHETICS
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian950, // Pure OLED Black #000000
      primaryColor: coral500,
      colorScheme: ColorScheme.dark(
        primary: coral500,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF3F1916),
        onPrimaryContainer: coral200,
        secondary: amber400,
        onSecondary: Colors.black,
        surface: slate850,             // #121214 (Pure neutral charcoal)
        onSurface: Colors.white,
        surfaceContainerHighest: slate800, // #18181B
        outline: slate700,
        outlineVariant: const Color(0xFF242428), // Delicate neutral border
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: slate850,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF242428), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral500,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: Color(0xFF27272A), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate850,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF242428), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF242428), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: coral500, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFF71717A)),
        prefixIconColor: const Color(0xFF71717A),
      ),
      dividerColor: const Color(0xFF1C1C1F),
    );
  }
}
