import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:raheeq_main/utils/colors.dart';
import '../authentication/login.dart';
import '../../storage/auth_storage.dart';
import '../../pages/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () async {
      final hasInternet =
          await InternetConnectionChecker.instance.hasConnection;

      if (mounted) {
        if (!hasInternet) {
          await AuthStorage.clear();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
          return;
        }

        final hasSession = AuthStorage.accessToken != null;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                hasSession ? const HomeScreen() : const Login(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.steelBlue,
      body: Center(
        child: Image.asset(
          'assets/Raheeq_LOGO_transparent.apng',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
