import 'dart:ui';
import 'package:flutter/material.dart';

/// Apple HIG-inspired Frosted Glass & Ambient Material System
/// Provides translucent vibrancy, specular borders, and layered depth.
class AppGlass {
  AppGlass._();

  /// Standard blur factors based on Apple Materials (Ultra-thin to Thick)
  static const double blurUltraThin = 8.0;
  static const double blurThin = 16.0;
  static const double blurRegular = 24.0;
  static const double blurThick = 40.0;

  /// Frosted glass decoration builder
  static BoxDecoration boxDecoration({
    required BuildContext context,
    double opacity = 0.75,
    double borderOpacity = 0.15,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Color? tintColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultRadius = borderRadius ?? BorderRadius.circular(24);

    final fill = tintColor != null
        ? tintColor.withValues(alpha: opacity)
        : isDark
            ? const Color(0xFF161F30).withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity)
        : Colors.black.withValues(alpha: borderOpacity * 0.5);

    return BoxDecoration(
      color: fill,
      borderRadius: defaultRadius,
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  /// Reusable Frosted Glass Container Widget with ImageFilter blur
  static Widget container({
    required BuildContext context,
    required Widget child,
    double blur = blurThin,
    double opacity = 0.75,
    double borderOpacity = 0.15,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    Color? tintColor,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: boxDecoration(
        context: context,
        opacity: opacity,
        borderOpacity: borderOpacity,
        borderRadius: radius,
        shadows: shadows,
        tintColor: tintColor,
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

/// Ambient Gradients & Glow Accents
class AppGradients {
  AppGradients._();

  /// Primary Sunset Aura (Coral -> Warm Amber)
  static const LinearGradient sunsetCoral = LinearGradient(
    colors: [
      Color(0xFFFF5E48), // Vibrant Coral
      Color(0xFFFF8A50), // Sunset Orange
      Color(0xFFFFA738), // Golden Amber
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep Obsidian / Midnight Slate card gradient
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [
      Color(0xFF1A2333),
      Color(0xFF101726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Scanner & AI Glow Accent
  static const LinearGradient aiPulse = LinearGradient(
    colors: [
      Color(0xFFFF5E48),
      Color(0xFF8B5CF6),
      Color(0xFF38BDF8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glass Sheen highlight
  static LinearGradient glassSpecular({required bool isDark}) {
    return LinearGradient(
      colors: [
        isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.6),
        isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.1),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

/// Ambient Elevation & Multi-layer Soft Shadows
class AppShadows {
  AppShadows._();

  static List<BoxShadow> subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : const Color(0xFF0F172A).withValues(alpha: 0.08),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : const Color(0xFF0F172A).withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> coralGlow = [
    BoxShadow(
      color: const Color(0xFFFF5E48).withValues(alpha: 0.35),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];
}
