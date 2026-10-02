import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/recent_history_service.dart';
import '../models/landmark.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'auth_screen.dart';
import 'explore_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.slate800, AppTheme.slate900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(HomeScreen.routeName),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppTheme.coral500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthService.currentName?.isNotEmpty == true
                                ? AuthService.currentName!
                                : 'Explorer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AuthService.currentEmail ??
                                'Discover the world with AI',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Stats
                ValueListenableBuilder<List<Landmark>>(
                  valueListenable:
                      RecentHistoryService().recentLandmarksNotifier,
                  builder: (context, landmarks, _) {
                    final historyService = RecentHistoryService();
                    return Row(
                      children: [
                        _buildStatCard(
                          '${historyService.uniqueLandmarksCount}',
                          'Landmarks',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          '${historyService.uniqueCitiesCount}',
                          'Cities',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          '${historyService.uniqueCountriesCount}',
                          'Countries',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Settings
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(Icons.language, 'Language', 'English'),
                      const Divider(height: 1),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return SwitchListTile(
                            secondary: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: AppTheme.slate600,
                            ),
                            title: Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme(value);
                            },
                            activeColor: AppTheme.coral500,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy & Trust
                Text(
                  'Privacy & Trust',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        Icons.shield_outlined,
                        'Data & Privacy',
                        null,
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        Icons.info_outline,
                        'AI Transparency',
                        null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? AppTheme.slate800
                        : AppTheme.coral50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? AppTheme.slate700
                          : AppTheme.coral100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Experience',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DigiGuide uses AI image recognition and language models to provide curated historical and cultural information.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AuthScreen.routeName,
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Bottom Nav
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  Icons.home_outlined,
                  'Home',
                  false,
                  HomeScreen.routeName,
                ),
                _buildNavItem(
                  context,
                  Icons.qr_code_scanner,
                  'Scan',
                  false,
                  CameraScreen.routeName,
                ),
                _buildNavItem(
                  context,
                  Icons.explore_outlined,
                  'Explore',
                  false,
                  ExploreScreen.routeName, // Fixed Navigation
                ),
                _buildNavItem(
                  context,
                  Icons.person,
                  'Profile',
                  true,
                  ProfileScreen.routeName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (gradient.colors.first).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.slate600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (value != null) ...[
            Text(
              value,
              style: const TextStyle(color: AppTheme.slate500, fontSize: 14),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, color: AppTheme.slate400, size: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    String? route,
  ) {
    return GestureDetector(
      onTap: () {
        if (route != null && !isActive) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.coral500 : AppTheme.slate400),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.coral500 : AppTheme.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
