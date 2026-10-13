import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/recent_history_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/tactile_bounce.dart';
import 'auth_screen.dart';
import 'camera_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final bool isEmbeddedInShell;

  const ProfileScreen({super.key, this.isEmbeddedInShell = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AuthScreen.routeName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName = AuthService.currentName?.isNotEmpty == true
        ? AuthService.currentName!
        : 'Makrand';
    final userEmail = AuthService.currentEmail ?? 'makrandghodke124@gmail.com';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Back Button (only if pushed standalone) & Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!widget.isEmbeddedInShell)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox.shrink(),
                    Text(
                      'Account & Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // 1. AVATAR & USER PROFILE CARD
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.slate850 : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: AppShadows.subtle(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: AppGradients.sunsetCoral,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.coralGlow,
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFA1A1AA)
                                    : AppTheme.slate500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.coral500.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DigiGuide Explorer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.coral500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 2. TRAVEL ACTIVITY STATS ROW
                // -------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Discovered',
                        value:
                            '${RecentHistoryService().recentLandmarksNotifier.value.length}',
                        icon: Icons.place_rounded,
                        color: AppTheme.coral500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<FavoritesProvider>(
                        builder: (context, fav, _) {
                          return _buildStatCard(
                            context,
                            title: 'Saved',
                            value: '${fav.favorites.length}',
                            icon: Icons.favorite_rounded,
                            color: Colors.pinkAccent,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Cities',
                        value: '1',
                        icon: Icons.location_city_rounded,
                        color: AppTheme.skyAzure,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // -------------------------------------------------------------
                // 3. SETTINGS GROUP (APPLE HIG STYLE)
                // -------------------------------------------------------------
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFA1A1AA) : AppTheme.slate500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.slate850 : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: AppShadows.subtle(context),
                  ),
                  child: Column(
                    children: [
                      // Language
                      _buildSettingsTile(
                        context,
                        icon: Icons.language_rounded,
                        title: 'Language',
                        trailingText: 'English',
                        onTap: () {},
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1F5F9),
                      ),
                      // Dark Mode Switch
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          final isCurrentDark = themeProvider.isDarkMode;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.coral500.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isCurrentDark
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    size: 20,
                                    color: AppTheme.coral500,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'OLED Dark Mode',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isCurrentDark,
                                  activeThumbColor: AppTheme.coral500,
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    themeProvider.toggleTheme(val);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // -------------------------------------------------------------
                // 4. PRIVACY & ARCHITECTURE GROUP
                // -------------------------------------------------------------
                Text(
                  'Privacy & Trust',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFA1A1AA) : AppTheme.slate500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.slate850 : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: AppShadows.subtle(context),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.shield_rounded,
                        title: 'Data & GPS Privacy',
                        onTap: () {},
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1F5F9),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Transparency & Model Docs',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // -------------------------------------------------------------
                // 5. SIGN OUT BUTTON
                // -------------------------------------------------------------
                TactileBounce(
                  onTap: _logout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF241517)
                          : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.coral500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppTheme.coral500,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppTheme.coral500,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Version info
                Center(
                  child: Text(
                    'DigiGuide v1.0.0 • Darmstadt Tour Engine',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF71717A)
                          : AppTheme.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isEmbeddedInShell
          ? null
          : FloatingGlassNavBar(
              currentIndex: 2,
              onTabSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).pushNamed(HomeScreen.routeName);
                } else if (index == 1) {
                  Navigator.of(context).pushNamed(ExploreScreen.routeName);
                }
              },
              onScanPressed: () {
                Navigator.of(context).pushNamed(CameraScreen.routeName);
              },
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate850 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFA1A1AA) : AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TactileBounce(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.slate800
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white70 : AppTheme.slate700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : AppTheme.slate500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFF71717A)
                  : AppTheme.slate400,
            ),
          ],
        ),
      ),
    );
  }
}
