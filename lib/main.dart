import 'package:country_picker/country_picker.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/services/network_monitor.dart';

import 'firebase_options.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/splashScreen/splash.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:raheeq_main/services/notification_service.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:raheeq_main/services/freshchat_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:raheeq_main/utils/colors.dart';

final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar'));

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// The cold-start profile check kicked off by [_initDependencies], or null if
/// init hasn't reached it yet. The splash screen awaits this (bounded) before
/// routing, so a dead session is caught before the user reaches the home
/// screen rather than after.
Future<void>? startupSessionCheck;

// The whole app renders at w700. Two things are needed and both are load-
// bearing:
//
//  - these families, each holding exactly one face (see pubspec.yaml). A
//    single-face family renders every requested [FontWeight] with that face,
//    which is what stops the inline w500/w600 styles scattered through the app
//    from opting out. Pointing at a normal multi-weight family would undo it.
//  - [MediaQueryData.boldText] below, so text that falls through to the
//    fallback fonts is asked for bold as well.
//
// Manrope carries no Arabic glyphs, so Arabic needs its own bundled face; left
// to the OS fallback there was no bold face available and Arabic could never
// bolden.
const String _latinFontFamily = 'ManropeBold';
const String _arabicFontFamily = 'NotoNaskhArabicBold';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Start the app immediately to show the splash screen
  runApp(const MainApp());

  // Initialize heavy dependencies in the background
  _initDependencies();
}

Future<void> _initDependencies() async {
  await dotenv.load(fileName: ".env");
  await AuthStorage.init();
  await AppStorage.init();
  localeNotifier.value = Locale(AppStorage.localeCode);

  // Kicked off, not awaited: this makes a network call, and it must not hold
  // up Firebase / notification setup below. The splash screen awaits the
  // stored future instead, so the result is still in hand before it routes.
  startupSessionCheck = _validateStoredSession();

  final ValueNotifier<double> snackbarBottomInset = ValueNotifier(0);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Permission.notification.request();

  // Initialize notification service
  await NotificationService().init();
  await NetworkMonitor.instance.start();

  NetworkMonitor.instance.onOffline = () {
    final context = AuthStorage.navigatorKey.currentContext;
    if (context == null) return;

    CustomSnackbar.show(
      context: context,
      message: AppLocalizations.of(context)!.internet_error,
      isError: true,
      bottomMargin: snackbarBottomInset.value,
    );
  };

  NetworkMonitor.instance.onOnline = () {
    final context = AuthStorage.navigatorKey.currentContext;
    if (context == null) return;

    CustomSnackbar.show(
      context: context,
      message: AppLocalizations.of(context)!.back_online,
      isError: false,
      bottomMargin: snackbarBottomInset.value,
    );
  };

  final freshchatAppId = dotenv.env['FRESHCHAT_APP_ID'];
  final freshchatAppKey = dotenv.env['FRESHCHAT_APP_KEY'];
  final freshchatDomain = dotenv.env['FRESHCHAT_DOMAIN'];

  if (freshchatAppId != null &&
      freshchatAppId.isNotEmpty &&
      freshchatAppKey != null &&
      freshchatAppKey.isNotEmpty &&
      freshchatDomain != null &&
      freshchatDomain.isNotEmpty) {
    Freshchat.init(freshchatAppId, freshchatAppKey, freshchatDomain);

    // Initialize Freshchat service listeners
    FreshchatService.init();

    // Allow a brief moment for the native SDK init to settle
    await Future.delayed(const Duration(milliseconds: 150));

    // Register this device's push token with Freshchat so it can deliver
    // push notifications for chat messages.
    await FreshchatService.registerPushToken();

    // Set user info if session exists
    try {
      final user = AuthStorage.user;
      if (user != null) {
        await FreshchatService.authenticateUser(user);
      }
    } catch (e) {
      debugPrint("Failed to set Freshchat user: $e");
    }
  }
}

/// Verifies the stored session against the server on cold start.
///
/// [ApiService.checkSession] — what the splash screen routes on — only reads
/// the access token's `exp` claim, so a token that was revoked server-side
/// (account deleted, session invalidated) still looks valid locally and the
/// app boots straight into the home screen. Hitting the profile endpoint once
/// at startup is what catches that: a 401 that survives the interceptor's
/// refresh-and-retry means the session is genuinely dead.
///
/// This only wipes storage — it never navigates. While
/// [AuthStorage.suppressLoginRedirect] is up the splash screen is the one
/// routing, and it sends the user to login once its own session check comes
/// back empty.
Future<void> _validateStoredSession() async {
  final token = AuthStorage.accessToken;
  if (token == null || token.isEmpty) {
    // No session to validate; the splash screen routes to login on its own.
    return;
  }

  try {
    await ApiService().getProfile();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      debugPrint('Startup profile check returned 401. Clearing session.');
      // Wipes tokens + userData from Hive and resets Freshchat.
      await AuthStorage.clear();
    }
    // Anything else (offline, timeout, 5xx) is not proof the session is bad,
    // so leave storage alone rather than logging the user out over a blip.
  } catch (e) {
    debugPrint('Startup profile check failed: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        final double bottomPadding = MediaQueryData.fromView(
          View.of(context),
        ).padding.bottom;
        final bool isThickNavBar = bottomPadding >= 24.0;

        return SafeArea(
          bottom: Platform.isAndroid ? isThickNavBar : false,
          top: false,
          child: MaterialApp(
            navigatorKey: AuthStorage.navigatorKey,
            navigatorObservers: [routeObserver],
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: MediaQuery(
                  data: mediaQueryData.copyWith(
                    textScaler: _ArabicTextScaler(
                      mediaQueryData.textScaler,
                      locale.languageCode == 'ar',
                    ),
                    boldText: true,
                  ),
                  child: child!,
                ),
              );
            },
            locale: locale,
            localizationsDelegates: const [
              CountryLocalizations.delegate,
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            theme: () {
              var theme = ThemeData(
                fontFamily: _latinFontFamily,
                // Arabic goes last so the riyal glyph and the existing Latin
                // fallback keep resolving exactly as they did before; Arabic
                // letters appear in none of those, so they fall through.
                fontFamilyFallback: const [
                  'SaudiRiyal',
                  'SF Pro',
                  _arabicFontFamily,
                ],
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColors.buttonBlueDark,
                  selectionHandleColor: AppColors.buttonBlueDark,
                  selectionColor: AppColors.buttonBlueDark.withOpacity(0.3),
                ),
                useMaterial3: true,
              );
              return theme;
            }(),
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {'/': (_) => const SplashScreen()},
          ),
        );
      },
    );
  }
}

class _ArabicTextScaler extends TextScaler {
  final TextScaler baseScaler;
  final bool isArabic;

  const _ArabicTextScaler(this.baseScaler, this.isArabic);

  @override
  double scale(double fontSize) {
    double scaled = baseScaler.scale(fontSize);
    return isArabic ? scaled + 2.0 : scaled + 1.0;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => baseScaler.textScaleFactor;
}
