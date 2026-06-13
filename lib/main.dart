import 'package:country_picker/country_picker.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freshchat_sdk/freshchat_user.dart';
import 'firebase_options.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/splashScreen/splash.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:raheeq_main/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app immediately to show the splash screen
  runApp(const MainApp());

  // Initialize heavy dependencies in the background
  _initDependencies();
}

Future<void> _initDependencies() async {
  await dotenv.load(fileName: ".env");
  await AuthStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Permission.notification.request();

  // Initialize notification service
  await NotificationService().init();

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

    // Set user info if session exists
    try {
      final user = AuthStorage.user;
      if (user != null) {
        FreshchatUser freshchatUser = await Freshchat.getUser;
        freshchatUser.setFirstName(user.firstName);
        freshchatUser.setLastName(user.lastName);
        freshchatUser.setEmail(user.email);
        freshchatUser.setPhone(user.countryCode, user.phoneNumber);
        Freshchat.setUser(freshchatUser);
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
        return MaterialApp(
          navigatorKey: AuthStorage.navigatorKey,
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
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}
