import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:math/core/services/theme_service.dart';
import 'package:math/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:math/core/services/network_service.dart';
import 'package:math/core/widgets/offline_banner.dart';
import 'package:math/core/services/app_usage_service.dart';
import 'package:math/core/services/continue_learning_service.dart';
import 'package:math/core/services/zen_mode_service.dart';
import 'package:math/features/social/feed/services/cache_service.dart';
import 'package:math/core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handler to catch WebView errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is PlatformException) {
      final exception = details.exception as PlatformException;
      if (exception.code == 'channel-error' &&
          exception.message?.contains('webview_flutter') == true) {
        if (kDebugMode) {
          print('Suppressed WebView error: ${exception.message}');
        }
        return;
      }
    }
    FlutterError.presentError(details);
  };

  await Firebase.initializeApp();

  // INITIALIZE APP CHECK
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleAppAttestProvider(),
  );

  // Enable edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await CacheService().init();
  await CacheService().clearOldCache();

  await SettingsService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService authService;
  late final AppRouter appRouter;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    appRouter = AppRouter(authService: authService);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => LanguageService()),
        ChangeNotifierProvider(create: (context) => AppUsageService()),
        ChangeNotifierProvider(
          create: (context) => ContinueLearningService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => NetworkService()..initialize(),
          lazy: false,
        ),
        ChangeNotifierProxyProvider<AuthService, StreakService>(
          create: (_) => StreakService(),
          update: (_, auth, previousStreak) =>
              previousStreak!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (context) => ZenModeService()),
        ChangeNotifierProvider.value(value: SettingsService()),
      ],
      child: Consumer2<ThemeService, LanguageService>(
        builder: (context, themeService, languageService, child) {
          SystemChrome.setSystemUIOverlayStyle(
            AppTheme.getSystemUIStyle(themeService.themeMode).copyWith(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
          );

          return ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Maths World',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeService.themeMode,
                debugShowCheckedModeBanner: false,
                routerConfig: appRouter.router,
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final mainApp = MediaQuery(
                    data: mediaQuery.copyWith(
                      viewPadding: mediaQuery.viewPadding,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                  return Consumer<NetworkService>(
                    builder: (context, networkService, _) {
                      return Stack(
                        children: [
                          mainApp, // This is our main app
                          OfflineBanner(
                            isOnline:
                                networkService.status == NetworkStatus.online,
                            justCameOnline: networkService.justCameOnline,
                          ),
                        ],
                      );
                    },
                  );
                },
                locale: languageService.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}
