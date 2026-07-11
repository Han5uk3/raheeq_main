import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/pages/order/track_donation_page.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init() async {
    _appLinks = AppLinks();
    
    // Check initial link if app was in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial app link: $e");
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("App Links stream error: $err");
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Received Deep Link: $uri");
    
    // Check path for specific actions
    final path = uri.path;
    final subOrderId = uri.queryParameters['subOrderId'];

    if (subOrderId == null || subOrderId.isEmpty) return;

    if (path.contains('/delivery-proof')) {
      _navigateToDeliveryProof(subOrderId);
    } else if (path.contains('/reorder')) {
      handleReorder(subOrderId);
    }
  }

  void _navigateToDeliveryProof(String subOrderId) {
    final context = AuthStorage.navigatorKey.currentContext;
    if (context == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackDonationPage(
          orderId: subOrderId,
          autoOpenProofs: true,
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
      builder: (_) => const WaterLoadingIndicator(),
    );

    try {
      final response = await ApiService().createReorder(subOrderId);
      Navigator.pop(context); // close loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        final checkoutDataMap = response.data['data'];
        final checkoutData = Checkout.fromJson(checkoutDataMap);
        
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
}
