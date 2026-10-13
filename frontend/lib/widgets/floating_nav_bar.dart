import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_glass.dart';
import 'tactile_bounce.dart';

/// Floating Frosted Glass Bottom Navigation Dock
/// Inspired by Apple iOS Floating Tab Bars and Google Material 3 Expressive.
class FloatingGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const FloatingGlassNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: AppGlass.container(
          context: context,
          blur: AppGlass.blurRegular,
          opacity: isDark ? 0.85 : 0.9,
          borderRadius: BorderRadius.circular(32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shadows: AppShadows.floating(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
              ),
              _buildScanAction(context),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.explore_rounded,
                label: 'Explore',
                isActive: currentIndex == 2,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TactileBounce(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppTheme.coral500.withValues(alpha: 0.18)
                  : AppTheme.coral50.withValues(alpha: 0.9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppTheme.coral500
                  : (isDark ? AppTheme.slate400 : AppTheme.slate500),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.coral500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Center elevated AI Scanner Button
  Widget _buildScanAction(BuildContext context) {
    return TactileBounce(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call(1);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: AppGradients.sunsetCoral,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.coralGlow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Scan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
