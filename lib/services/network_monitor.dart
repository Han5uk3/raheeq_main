import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum NetworkStatus { online, poor, offline }

class NetworkMonitor {
  NetworkMonitor._();

  static final NetworkMonitor instance = NetworkMonitor._();

  final ValueNotifier<NetworkStatus> status = ValueNotifier(
    NetworkStatus.online,
  );

  final Connectivity _connectivity = Connectivity();

  late final Dio _healthDio = Dio(
    BaseOptions(
      baseUrl: 'https://api-staging.suqyarahiq.com/api/v1',
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
      headers: {'Accept': 'application/json'},
    ),
  );

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _timer;

  bool _isChecking = false;

  VoidCallback? onOnline;
  VoidCallback? onOffline;
  VoidCallback? onPoorNetwork;

  Future<void> start() async {
    await _checkNetwork();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      _,
    ) async {
      // Give the OS a moment to establish connectivity.
      await Future.delayed(const Duration(seconds: 2));
      await _checkNetwork();
    });

    _scheduleNextCheck();
  }

  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    _timer?.cancel();
  }

  void _scheduleNextCheck() {
    _timer?.cancel();

    Duration interval;

    switch (status.value) {
      case NetworkStatus.online:
        interval = const Duration(seconds: 30);
        break;

      case NetworkStatus.poor:
        interval = const Duration(seconds: 10);
        break;

      case NetworkStatus.offline:
        interval = const Duration(seconds: 5);
        break;
    }

    _timer = Timer(interval, () async {
      await _checkNetwork();
      _scheduleNextCheck();
    });
  }

  Future<void> _checkNetwork() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      final hasInternet = await InternetConnection().hasInternetAccess;

      if (!hasInternet) {
        _updateStatus(NetworkStatus.offline);
        return;
      }

      final stopwatch = Stopwatch()..start();
      log('health dio url: ${_healthDio.options.baseUrl}');
      final response = await _healthDio.get('/health');
      log('health response: ${response.data}');

      stopwatch.stop();

      if (response.statusCode != 200) {
        _updateStatus(NetworkStatus.offline);
        return;
      }

      final latency = stopwatch.elapsedMilliseconds;

      if (latency < 500) {
        _updateStatus(NetworkStatus.online);
      } else if (latency < 2000) {
        _updateStatus(NetworkStatus.poor);
      } else {
        _updateStatus(NetworkStatus.offline);
      }
    } on DioException {
      _updateStatus(NetworkStatus.offline);
    } catch (_) {
      _updateStatus(NetworkStatus.offline);
    } finally {
      _isChecking = false;
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (status.value == newStatus) {
      return;
    }

    status.value = newStatus;

    switch (newStatus) {
      case NetworkStatus.online:
        onOnline?.call();
        break;

      case NetworkStatus.offline:
        onOffline?.call();
        break;

      case NetworkStatus.poor:
        onPoorNetwork?.call();
        break;
    }
  }
}
