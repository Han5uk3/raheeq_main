import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/main.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import '../authentication/login.dart';
import '../../pages/home/home_screen.dart';

/// How much longer than the splash animation we'll wait on the cold-start
/// profile check before routing without it. The check starts alongside the
/// 3500 ms timer, so this is extra time on top of that head start.
const Duration _sessionCheckGrace = Duration(seconds: 2);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  /// Shown when we couldn't verify the session because of a network/server
  /// error. Lets the user retry instead of being logged out.
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() {
    Future.delayed(const Duration(milliseconds: 3500), _decideRoute);
  }

  Future<void> _decideRoute() async {
    if (mounted) {
      setState(() => _showRetry = false);
    }

    // Wait for Hive storage to be fully initialized before reading tokens.
    // _initDependencies() in main.dart runs in the background, so there is
    // no guarantee it finishes before this 3500 ms timer fires.
    await AuthStorage.ready;

    // The cold-start profile check runs in parallel with the 3500 ms timer
    // above and has usually landed by now. Await it so a revoked session is
    // known before we route — otherwise we'd send the user to Home and the
    // late 401 would bounce them straight back out. Bounded, so a slow or
    // hanging request can't pin the splash on screen: if it outruns the
    // grace period we route on local token state and the API client's normal
    // 401 handling catches the session on the next call.
    try {
      await startupSessionCheck?.timeout(_sessionCheckGrace);
    } catch (e) {
      log("Splash: startup profile check did not settle in time: $e");
    }

    final status = await _apiService.checkSession();
    log("Splash session check: $status");

    // Routing decision made — session failures from here on redirect on
    // their own instead of waiting for the splash.
    AuthStorage.suppressLoginRedirect = false;

    if (!mounted) return;

    switch (status) {
      case SessionStatus.valid:
        Navigator.of(context).pushReplacement(HomeScreen.route());
        break;

      case SessionStatus.invalid:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()),
        );
        break;

      case SessionStatus.networkError:
        setState(() => _showRetry = true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.steelBlue,
      body: Center(
        child: _showRetry
            ? _buildRetryState()
            : Image.asset(
                'assets/splash/splash_animation.apng',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _buildRetryState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.internet_error,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _decideRoute,
          child: Text(AppLocalizations.of(context)!.retry),
        ),
      ],
    );
  }
}
