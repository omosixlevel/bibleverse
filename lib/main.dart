import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/bible_service.dart';
import 'core/services/inspired_alert_service.dart';
import 'core/services/gemini_coach_service.dart';
import 'core/services/mock_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/data/repository.dart'; // Import Repository
import 'core/providers/app_navigation_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'features/splash/splash_screen.dart'; // Import Splash Screen
import 'package:timezone/data/latest.dart' as tz;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase with the manual configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully with manual options');

    // Auto-login anonymously for the Demo/Hackathon
    final authService = AuthService();
    await authService.signInAnonymously();
    // Initialize Mock Storage for Offline-First behavior
    await MockStorageService().initialize();

    // Initialize timezone data for notifications
    tz.initializeTimeZones();

    // Initialize Notification Service
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase/Auth initialization failed: $e');
  }
  runApp(const BibleverseApp());
}

class BibleverseApp extends StatelessWidget {
  const BibleverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<MockStorageService>(create: (_) => MockStorageService()),
        // Inject Repository (depends on FirestoreService)
        // Inject Repository (depends on FirestoreService and MockStorageService)
        ProxyProvider2<FirestoreService, MockStorageService, Repository>(
          update: (_, firestoreService, mockStorage, __) =>
              Repository(firestoreService, mockStorage),
        ),
        Provider<BibleService>(create: (_) => BibleService()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        ChangeNotifierProvider<InspiredAlertService>(
          create: (_) => InspiredAlertService(),
        ),
        ChangeNotifierProvider<AppNavigationProvider>(
          create: (_) => AppNavigationProvider(),
        ),
        ProxyProvider<InspiredAlertService, GeminiCoachService>(
          update: (_, alertService, __) =>
              GeminiCoachService(alertService: alertService),
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) => MaterialApp(
          title: 'Bibleverse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('fr')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Start with Splash Screen
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
