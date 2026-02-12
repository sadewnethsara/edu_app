import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:math/app_exports.dart';
import 'package:math/l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:math/firebase_options.dart';
import 'package:math/features/social/feed/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleAppAttestProvider(),
  );

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
        ChangeNotifierProvider(create: (context) => SettingsService()..init()),
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
                          mainApp,
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
