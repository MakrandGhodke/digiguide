import 'package:flutter/material.dart';

/// Screen device categories based on Apple HIG & Material 3 adaptive layout specifications
enum DeviceScreenType {
  compact,  // Mobile phones (< 600dp)
  medium,   // Foldables & Small tablets (600dp - 960dp)
  expanded, // Large tablets & Desktop / Web (> 960dp)
}

/// Adaptive Layout Helper ensuring fluid responsiveness across all screens & orientations
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double breakpointCompact = 600.0;
  static const double breakpointMedium = 960.0;
  static const double maxContentWidth = 1120.0;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpointCompact) return DeviceScreenType.compact;
    if (width < breakpointMedium) return DeviceScreenType.medium;
    return DeviceScreenType.expanded;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointCompact;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= breakpointCompact && width < breakpointMedium;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointMedium;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Dynamic horizontal padding that scales gracefully with screen width
  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpointCompact) {
      return const EdgeInsets.symmetric(horizontal: 20);
    } else if (width < breakpointMedium) {
      return const EdgeInsets.symmetric(horizontal: 36);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }

  /// Calculates responsive column counts for grids (e.g. Landmark cards)
  static int gridColumns(BuildContext context, {int compact = 1, int medium = 2, int expanded = 3}) {
    if (isMobile(context)) return compact;
    if (isTablet(context)) return medium;
    return expanded;
  }
}

/// A container that clamps maximum layout width on large displays (tablets/foldables/web)
/// to avoid stretched wide interfaces while maintaining fluid full-bleed on phones.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
