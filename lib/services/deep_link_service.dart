import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/services/network_monitor.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _pendingDeepLink;

  Future<void> init() async {
    if (_linkSubscription != null) return;

    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        final lastProcessed = AppStorage.lastProcessedDeepLink;
        if (lastProcessed != initialUri.toString()) {
          AppStorage.saveLastProcessedDeepLink(initialUri.toString());
          _handleDeepLink(initialUri);
        }
      }
    } catch (e) {
      debugPrint("Failed to get initial app link: $e");
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint("App Links stream error: $err");
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Received Deep Link: $uri");

    if (AuthStorage.accessToken == null) {
      _pendingDeepLink = uri;
      return;
    }

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return;

    String? subOrderId;
    if (pathSegments.length >= 2) {
      subOrderId = pathSegments.last;
    } else {
      subOrderId = uri.queryParameters['subOrderId'];
    }

    if (subOrderId == null || subOrderId.isEmpty) return;

    final path = uri.path;
    if (path.contains('/delivery-video')) {
      _navigateToDeliveryProof(subOrderId, autoPlayVideo: true);
    } else if (path.contains('/delivery-proof')) {
      _navigateToDeliveryProof(subOrderId);
    } else if (path.contains('/reorder')) {
      handleReorder(subOrderId);
    }
  }

  void _navigateToDeliveryProof(
    String subOrderId, {
    bool autoPlayVideo = false,
  }) {
    final context = AuthStorage.navigatorKey.currentContext;
    if (context == null) return;

    HomeScreen.switchTabNotifier.value = 1;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailsPage(
          orderId: subOrderId,
          autoPlayVideo: autoPlayVideo,
        ),
      ),
    );
  }

  Future<void> handleReorder(String subOrderId) async {
    final context = AuthStorage.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: const WaterLoadingIndicator(),
        ),
      ),
    );

    try {
      if (NetworkMonitor.instance.status == NetworkStatus.offline) {
        CustomSnackbar.show(
          isError: true,
          context: context,
          message: AppLocalizations.of(context)!.internet_error,
        );
        return;
      }
      final response = await ApiService().createReorder(subOrderId);
      Navigator.pop(context); // close loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        final checkoutDataMap = response.data['data'];
        final checkoutData = Checkout.fromJson(checkoutDataMap);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributionDetailsPage(
              orderStates: const [],
              donationType: AppLocalizations.of(context)!.one_time_donation,
              checkoutData: checkoutData,
            ),
          ),
        );
      } else {
        CustomSnackbar.show(
          context: context,
          message: response.data['message'] ?? 'Reorder failed',
          isError: true,
        );
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      CustomSnackbar.show(
        context: context,
        message: 'An error occurred during reorder',
        isError: true,
      );
    }
  }

  void processPendingDeepLink() {
    if (_pendingDeepLink != null && AuthStorage.accessToken != null) {
      final uri = _pendingDeepLink!;
      _pendingDeepLink = null;
      _handleDeepLink(uri);
    }
  }
}
