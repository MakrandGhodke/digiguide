import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_glass.dart';
import 'tactile_bounce.dart';

/// Ultra-Sleek Symmetrical Floating Navigation Dock
/// Designed with Apple HIG precision, frosted glass vibrancy, and tactile haptic feedback.
class FloatingGlassNavBar extends StatelessWidget {
  /// Active tab index: 0 = Home, 1 = Explore, 2 = Profile
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onScanPressed;

  const FloatingGlassNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
    this.onScanPressed,
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
          opacity: isDark ? 0.88 : 0.92,
          borderRadius: BorderRadius.circular(32),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shadows: AppShadows.floating(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Home Tab
              _buildNavButton(
                context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
              ),

              // 2. Explore Tab
              _buildNavButton(
                context,
                index: 1,
                icon: Icons.explore_rounded,
                label: 'Explore',
                isActive: currentIndex == 1,
              ),

              // 3. Center Elevated AI Scan Action
              _buildCenterScanButton(context),

              // 4. Profile Tab
              _buildNavButton(
                context,
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TactileBounce(
      enableHaptic: true,
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected?.call(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? const Color(0xFF222226) // Refined dark charcoal pill
                  : AppTheme.coral50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppTheme.coral500.withValues(alpha: 0.2),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppTheme.coral500
                  : (isDark ? const Color(0xFF71717A) : AppTheme.slate400),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.coral600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Refined Center Scan Capsule Button
  Widget _buildCenterScanButton(BuildContext context) {
    return TactileBounce(
      enableHaptic: true,
      onTap: () {
        HapticFeedback.mediumImpact();
        onScanPressed?.call();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: AppGradients.sunsetCoral,
          borderRadius: BorderRadius.circular(21),
          boxShadow: AppShadows.coralGlow,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 5),
            Text(
              'Scan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
