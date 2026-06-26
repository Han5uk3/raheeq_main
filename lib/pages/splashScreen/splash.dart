import 'package:flutter/material.dart';
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/splashbg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Center(
            child: Image.asset(
              'assets/Raheeq_LOGO_transparent.apng',
              width: MediaQuery.of(context).size.width,
            ),
          ),
        ],
      ),
    );
  }
}
