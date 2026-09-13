import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:raheeq_main/api/api_logger.dart';

enum NetworkStatus { online, poor, offline }

class NetworkMonitor with WidgetsBindingObserver {
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
  )..interceptors.add(ApiLogger());

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _timer;

  bool _isChecking = false;

  // Confirmation state: a proposed status must survive for
  // _confirmWindow before it's committed.
  NetworkStatus? _pendingStatus;
  DateTime? _pendingSince;
  static const Duration _confirmWindow = Duration(seconds: 6);

  // After resume from background, give the connection a moment
  // to warm back up before trusting a bad reading.
  DateTime? _resumedAt;
  static const Duration _resumeGrace = Duration(seconds: 4);

  VoidCallback? onOnline;
  VoidCallback? onOffline;
  VoidCallback? onPoorNetwork;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);

    await _checkNetwork(isWarmup: true);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      _,
    ) async {
      await Future.delayed(const Duration(seconds: 2));
      await _checkNetwork();
    });

    _scheduleNextCheck();
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySubscription?.cancel();
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumedAt = DateTime.now();
      log('NetworkMonitor: app resumed, entering grace period');
      // Re-check shortly after resume, but the grace period below
      // stops a single cold/slow reading from flipping the toast.
      Future.delayed(const Duration(milliseconds: 500), _checkNetwork);
    }
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

  Future<void> _checkNetwork({bool isWarmup = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    final inGrace =
        _resumedAt != null &&
        DateTime.now().difference(_resumedAt!) < _resumeGrace;

    try {
      final hasInternet = await InternetConnection().hasInternetAccess;

      if (!hasInternet) {
        log('NetworkMonitor: no internet access (grace=$inGrace)');
        if (!inGrace) _proposeStatus(NetworkStatus.offline);
        return;
      }

      final stopwatch = Stopwatch()..start();
      final response = await _healthDio.get('/health');
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (isWarmup) {
        // Don't let the cold-start call affect status at all.
        return;
      }

      if (response.statusCode != 200) {
        if (!inGrace) _proposeStatus(NetworkStatus.offline);
        return;
      }

      if (latency < 800) {
        _proposeStatus(NetworkStatus.online);
      } else if (latency < 2500) {
        if (!inGrace) _proposeStatus(NetworkStatus.poor);
      } else {
        if (!inGrace) _proposeStatus(NetworkStatus.offline);
      }
    } on DioException catch (e) {
      log('NetworkMonitor: DioException ${e.type} (grace=$inGrace)');
      if (!inGrace) _proposeStatus(NetworkStatus.offline);
    } catch (e) {
      log('NetworkMonitor: error $e (grace=$inGrace)');
      if (!inGrace) _proposeStatus(NetworkStatus.offline);
    } finally {
      _isChecking = false;
    }
  }

  // Time-based confirmation: a proposed status has to be the most
  // recent reading for _confirmWindow straight before it commits.
  // Any reading that matches the *current* status cancels the pending change.
  void _proposeStatus(NetworkStatus proposed) {
    if (proposed == status.value) {
      _pendingStatus = null;
      _pendingSince = null;
      return;
    }

    final now = DateTime.now();

    if (_pendingStatus != proposed) {
      _pendingStatus = proposed;
      _pendingSince = now;
      log('NetworkMonitor: proposing $proposed, starting confirm window');
      return;
    }

    if (now.difference(_pendingSince!) >= _confirmWindow) {
      _updateStatus(proposed);
      _pendingStatus = null;
      _pendingSince = null;
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    final previous = status.value;
    if (previous == newStatus) return;

    log('NetworkMonitor: status $previous -> $newStatus');
    status.value = newStatus;

    switch (newStatus) {
      case NetworkStatus.online:
        if (previous == NetworkStatus.offline ||
            previous == NetworkStatus.poor) {
          onOnline?.call();
        }
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
