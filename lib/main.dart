import 'package:country_picker/country_picker.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
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

    // Register this device's FCM token with Freshchat so it can deliver
    // push notifications for chat messages.
    await FreshchatService.registerPushToken();

    // Set user info if session exists
    try {
      final user = AuthStorage.user;
      if (user != null) {
        await FreshchatService.identifyUser(user);
      }
    } catch (e) {
      debugPrint("Failed to set Freshchat user: $e");
    }
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
        final bool isThickNavBar = bottomPadding > 24.0;

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
                      true,
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
    return isArabic ? scaled + 1.0 : scaled;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => baseScaler.textScaleFactor;
}
