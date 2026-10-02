import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'theme/app_theme.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/ai_processing_screen.dart';
import 'screens/landmark_result_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/favorites_screen.dart';
import 'services/recent_history_service.dart';
import 'services/audio_tour_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted services
  await RecentHistoryService().loadHistory();
  await AuthService.init();

  runApp(const DigiGuideApp());
}

class DigiGuideApp extends StatelessWidget {
  const DigiGuideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine initial route based on auth status
    String initialRoute;
    if (AuthService.isLoggedIn) {
      initialRoute = HomeScreen.routeName;
    } else {
      initialRoute = AuthScreen.routeName;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AudioTourService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'DigiGuide',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Start based on auth status
            initialRoute: initialRoute,
            routes: {
              AuthScreen.routeName: (_) => const AuthScreen(),
              OnboardingScreen.routeName: (_) => const OnboardingScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              CameraScreen.routeName: (ctx) => const CameraScreen(),
              AIProcessingScreen.routeName: (ctx) {
                final args =
                    ModalRoute.of(ctx)!.settings.arguments
                        as Map<String, dynamic>;
                return AIProcessingScreen(imageFile: args['image'] as File);
              },
              LandmarkResultScreen.routeName: (ctx) =>
                  const LandmarkResultScreen(),
              ProfileScreen.routeName: (ctx) => const ProfileScreen(),
              ExploreScreen.routeName: (ctx) => const ExploreScreen(),
              FavoritesScreen.routeName: (ctx) => const FavoritesScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AIProcessingScreen.routeName) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) =>
                      AIProcessingScreen(imageFile: args['image'] as File),
                );
              }
              if (settings.name == LandmarkResultScreen.routeName) {
                return MaterialPageRoute(
                  builder: (context) => const LandmarkResultScreen(),
                  settings:
                      settings, // Pass settings so arguments are available
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
