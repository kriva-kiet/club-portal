import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/service_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first
  final sharedPreferences = await SharedPreferences.getInstance();

  // Attempt Firebase init — falls back to Mock Mode on unsupported platforms
  // (e.g. macOS desktop, web when not configured)
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAvailable = true;
    debugPrint('✅ Firebase initialized successfully.');
    // First-ever launch: default to Mock Mode so test credentials work.
    // Users can toggle to Live when Firebase users are configured.
    if (!sharedPreferences.containsKey('use_mock_mode_v1')) {
      await sharedPreferences.setBool('use_mock_mode_v1', true);
      debugPrint('   → No mode preference found. Defaulting to Mock Mode.');
    }
  } on UnsupportedError catch (e) {
    debugPrint('⚠️  Firebase not supported on this platform: $e');
    debugPrint('   → Switching to Mock Mode automatically.');
    await sharedPreferences.setBool('use_mock_mode_v1', true);
  } catch (e) {
    debugPrint('⚠️  Firebase init failed: $e');
    debugPrint('   → Switching to Mock Mode automatically.');
    await sharedPreferences.setBool('use_mock_mode_v1', true);
  }

  // On mobile, lock to portrait orientation
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {
      // Desktop platforms don't support orientation lock — ignore
    }
  }

  // Immersive status bar styling (mobile only)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B0F19),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: KrivaApp(firebaseAvailable: firebaseAvailable),
    ),
  );
}

class KrivaApp extends ConsumerWidget {
  final bool firebaseAvailable;
  const KrivaApp({super.key, required this.firebaseAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final useMock = ref.watch(useMockModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'KRIVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        // Show a banner when running in Mock Mode so it's always obvious
        if (useMock) {
          return Stack(
            children: [
              child,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⚡ MOCK MODE — No Firebase',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return child;
      },
    );
  }
}
