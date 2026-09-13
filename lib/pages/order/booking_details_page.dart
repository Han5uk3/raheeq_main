import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/chiller_refill_badge.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/payment_method_badge.dart';
import 'package:raheeq_main/pages/order/payment_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/proof_media_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:video_player/video_player.dart';
import 'package:raheeq_main/utils/formatters.dart';

class BookingDetailsPage extends StatefulWidget {
  final String orderId;
  final bool autoPlayVideo;

  const BookingDetailsPage({
    super.key,
    required this.orderId,
    this.autoPlayVideo = false,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  OrderResponseModel? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getOrderDetails(widget.orderId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _order = OrderResponseModel.fromJson(response.data['data']);
          _isLoading = false;
        });

        if (widget.autoPlayVideo &&
            _order?.deliveryProof != null &&
            _order!.deliveryProof!['deliveryVideo'] != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                List<ProofMediaItem> mediaItems = _getMediaItems(_order!);
                int videoIndex = mediaItems.indexWhere((item) => item.isVideo);
                if (videoIndex != -1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProofMediaViewerPage(
                        mediaItems: mediaItems,
                        initialIndex: videoIndex,
                        orderNumber: _order?.subOrderNumber,
                      ),
                    ),
                  );
                }
              }
            });
          });
        }
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      log(
        'Error fetching order details: $e',
        name: 'BookingDetailsPage',
        error: e,
      );
      String errorMessage = 'Failed to load order details';
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If order_details key doesn't exist, use fallback
    String title = "";
    try {
      title = AppLocalizations.of(context)!.order_details;
    } catch (_) {
      title = "Order Details";
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: title,
              subtitle: _order?.subOrderNumber ?? "",
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
                  child: _buildContent(isAr),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required TextStyle style}) {
    return Text(title, style: style);
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: child),
    );
  }

  Widget _buildContent(bool isAr) {
    final style = PaymentMethodStyle.resolve(
      context,
      _order?.parentOrder?.paymentMethod ?? "",
    );
    if (_isLoading) {
      return Padding(
        key: const ValueKey('loader'),
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.error_title,
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: _fetchOrderDetails,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final order = _order!;

    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sits above everything else so a refill is identified before the
          // reader works through the product and location cards.
          if (order.isChillerRefill)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: ChillerRefillBadge(),
            ),
          Builder(
            builder: (context) {
              final bool showInvoice =
                  order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty;
              final bool showReorder =
                  order.status.toUpperCase() == 'CONFIRMED';

              if (!showInvoice && !showReorder) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    if (showReorder)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlueDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            DeepLinkService().handleReorder(order.id);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AppLocalizations.of(context)!.reorder,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // Subscription details. Above the product so a recurring order is
          // read as part of a plan before its contents.
          if (order.subscription != null) ...[
            _buildSubscriptionCard(order.subscription!, isAr),
            // Every card below brings its own leading gap, so this one is
            // only needed for the product card that does not.
            if (order.product != null) const SizedBox(height: 12),
          ],

          // Product details
          if (order.product != null) ...[
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.product_details,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: order.product!.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? order.product!.nameAr
                                  : order.product!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context)!.quantity}: ${order.product!.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Target and Location details
          if (order.target != null ||
              order.locationDetails != null ||
              order.deliveredLocationDetails != null) ...[
            const SizedBox(height: 12),
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.location_details,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (order.target != null) ...[
                    _buildInfoRow(
                      AppLocalizations.of(context)!.location,
                      isAr ? order.target!.labelAr : order.target!.label,
                    ),
                  ],
                  if (order.locationDetails != null &&
                      order.locationDetails!['address'] != null)
                    _buildInfoRow(
                      AppLocalizations.of(context)!.address,
                      order.locationDetails!['address'].toString(),
                    ),
                ],
              ),
            ),
          ],

          if (order.deliveredToDifferentMosque == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.deliveredToDifferentLocation,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.differentMosqueReason != null &&
                            order.differentMosqueReason!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${AppLocalizations.of(context)!.reasonForDifferentLocation}: ${order.differentMosqueReason}',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Delivery Proofs
          _buildDeliveryProofs(order),
          const SizedBox(height: 12),

          // Gift Card details
          if (order.giftCard != null) ...[
            Builder(
              builder: (context) {
                final String? giftCardUrl =
                    order.giftCard!['generatedImage'] ??
                    order.giftCard!['image'] ??
                    order.giftCard!['url'] ??
                    order.giftCard!['pdfUrl']; // add fallbacks just in case

                if (giftCardUrl == null) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildPremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            AppLocalizations.of(context)!.gift_card,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    appBar: AppBar(
                                      backgroundColor: Colors.black,
                                      iconTheme: const IconThemeData(
                                        color: Colors.white,
                                      ),
                                    ),
                                    body: Center(
                                      child: InteractiveViewer(
                                        child: CachedNetworkImage(
                                          imageUrl: giftCardUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: giftCardUrl,
                                height: 290,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        height: 290,
                                        width: double.infinity,
                                        color: Colors.white,
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  height: 290,
                                  width: double.infinity,
                                  child: const Center(child: Icon(Icons.error)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (order.financials != null) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PaymentDetailsPage(
                    isAr: isAr,
                    order: order,
                    financials:
                        order.financials ??
                        OrderFinancials(
                          unitPrice: 0,
                          amount: 0,
                          deliveryFee: 0,
                          vatAmount: 0,
                          walletAmount: 0,
                          discountAmount: 0,
                          totalAmount: 0,
                        ),
                  ),
                ),
              ),
              child: _buildPremiumCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.payment_details,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (style.secondaryAsset != null) ...[
                              _logo(style.secondaryAsset!),
                              const SizedBox(width: 4),
                            ],
                            if (style.asset != null)
                              _logo(style.asset!)
                            else
                              // Placeholder for the methods that ship no logo yet.
                              Icon(style.icon, size: 16, color: style.color),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12), // spacing at bottom
          ],

          // Delivery Progress
          _buildDeliveryProgressCard(order),
          const SizedBox(height: 12),

          // Customer Review
          if (order.review != null) ...[
            _buildPremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.review,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < order.review!.rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  if (order.review!.reviewText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      order.review!.reviewText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// The delivery fee row, which reads "SAR 25.00  Free" — original struck
  /// through — instead of a bare "SAR 0" when the delivery was free.

  Widget _logo(String asset) => SizedBox(
    height: 40,
    width: 40,
    child: Image.asset(asset, fit: BoxFit.contain),
  );

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// The plan an order recurs on, shown only for orders the backend links to
  /// a subscription.
  Widget _buildSubscriptionCard(OrderSubscription subscription, bool isAr) {
    final plan = subscription.plan;
    final Color statusColor = _subscriptionStatusColor(subscription.status);
    final bool hasDetailRows =
        subscription.subscriptionNumber.isNotEmpty ||
        subscription.startDate != null ||
        subscription.endDate != null;

    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppLocalizations.of(context)!.subscription_details,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan != null && plan.image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: plan.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.event_repeat_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (plan != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? plan.nameAr : plan.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan.frequency.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _localizeFrequency(plan.frequency),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                const Spacer(),
              if (subscription.status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _localizeSubscriptionStatus(subscription.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasDetailRows) const Divider(height: 32),
          if (subscription.subscriptionNumber.isNotEmpty)
            _buildInfoRow(
              AppLocalizations.of(context)!.subscription_number,
              _order?.subOrderNumber ?? "",
            ),
          if (subscription.startDate != null)
            _buildInfoRow(
              AppLocalizations.of(context)!.start_date,
              Formatters.formatDateWithWeekday(
                context,
                subscription.startDate!,
              ),
            ),
          if (subscription.endDate != null)
            _buildInfoRow(
              AppLocalizations.of(context)!.end_date,
              Formatters.formatDateWithWeekday(context, subscription.endDate!),
            ),
        ],
      ),
    );
  }

  String _localizeFrequency(String frequency) {
    switch (frequency.toLowerCase().trim()) {
      case 'everyday':
        return AppLocalizations.of(context)!.everyday;
      case 'once_a_week':
        return AppLocalizations.of(context)!.once_a_week;
      case 'twice_a_week':
        return AppLocalizations.of(context)!.twice_a_week;
      case 'once_a_month':
        return AppLocalizations.of(context)!.once_a_month;
      case 'custom':
        return AppLocalizations.of(context)!.custom;
      default:
        return frequency;
    }
  }

  String _localizeSubscriptionStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'active':
        return AppLocalizations.of(context)!.status_active;
      case 'cancelled':
        return AppLocalizations.of(context)!.status_cancelled;
      case 'expired':
        return AppLocalizations.of(context)!.status_expired;
      case 'pending':
        return AppLocalizations.of(context)!.status_pending;
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1).toLowerCase()
            : '';
    }
  }

  Color _subscriptionStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'active':
        return Colors.green;
      case 'cancelled':
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDeliveryProgressCard(OrderResponseModel order) {
    final bool isOrderPlaced = true;
    final bool isOutForDelivery =
        order.driver != null ||
        order.status == 'DISPATCHED' ||
        order.status == 'OUT_FOR_DELIVERY' ||
        order.status == 'DELIVERED' ||
        order.status == 'CONFIRMED' ||
        order.status == 'COMPLETED';
    final bool isDelivered =
        order.status == 'CONFIRMED' || order.status == 'COMPLETED';

    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppLocalizations.of(context)!.delivery_progress,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.order_placed,
            date: order.createdAt,
            isReached: isOrderPlaced,
            isLast: false,
            icon: Icons.receipt_long,
          ),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.out_for_delivery,
            date:
                order.assignedAt ??
                ((order.status == 'CONFIRMED' || order.status == 'COMPLETED')
                    ? (order.confirmedAt ?? order.completedAt)
                    : null),
            isReached: isOutForDelivery,
            isLast: false,
            icon: Icons.local_shipping,
          ),
          _buildTimelineItem(
            title: AppLocalizations.of(context)!.delivery_completed,
            date: order.completedAt ?? order.confirmedAt,
            isReached: isDelivered,
            isLast: true,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? date,
    required bool isReached,
    required bool isLast,
    required IconData icon,
  }) {
    final Color color = isReached
        ? AppColors.buttonBlueDark
        : Colors.grey[300]!;

    String formattedDate = '';
    if (date != null) {
      formattedDate = Formatters.formatDateWithWeekday(context, date);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isReached ? color : Colors.grey[100],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isReached ? AppColors.buttonBlueDark : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                    color: isReached ? Colors.black : Colors.grey,
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ProofMediaItem> _getMediaItems(OrderResponseModel order) {
    if (order.deliveryProof == null || order.deliveryProof!.isEmpty) {
      return [];
    }

    final proofs = order.deliveryProof!;
    List<ProofMediaItem> mediaItems = [];

    if (proofs['mosqueFrontImage'] != null &&
        proofs['mosqueFrontImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.mosque_front,
          fileLabel: 'mosque_front',
          url: proofs['mosqueFrontImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['mosqueInsideImage'] != null &&
        proofs['mosqueInsideImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.mosque_inside,
          fileLabel: 'mosque_inside',
          url: proofs['mosqueInsideImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['packagesImage'] != null &&
        proofs['packagesImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.proof_product,
          fileLabel: 'product_image',
          url: proofs['packagesImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['deliveryVideo'] != null &&
        proofs['deliveryVideo'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          thumbnail: proofs['deliveryVideoThumbnail'],
          title: AppLocalizations.of(context)!.delivery_video,
          fileLabel: 'video',
          url: proofs['deliveryVideo'],
          isVideo: true,
        ),
      );
    }
    return mediaItems;
  }

  Widget _buildDeliveryProofs(OrderResponseModel order) {
    final mediaItems = _getMediaItems(order);

    if (mediaItems.isEmpty) return const SizedBox.shrink();

    List<Widget> proofItems = [];
    for (int i = 0; i < mediaItems.length; i++) {
      proofItems.add(_buildSmallProofCard(mediaItems[i], i, mediaItems));
    }

    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppLocalizations.of(context)!.proof_of_delivery,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (index) {
              if (index.isOdd) {
                return const SizedBox(width: 8.0);
              }
              int itemIndex = index ~/ 2;
              if (itemIndex < proofItems.length) {
                return Expanded(child: proofItems[itemIndex]);
              } else {
                return const Expanded(child: SizedBox.shrink());
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallProofCard(
    ProofMediaItem item,
    int index,
    List<ProofMediaItem> allMedia,
  ) {
    final isVideo = item.isVideo;
    final thumbnail = item.thumbnail;
    final hasThumbnail = isVideo && thumbnail != null && thumbnail.isNotEmpty;

    // Stands in for the video when the backend sent no thumbnail, or when the
    // one it sent fails to load.
    Widget videoPlaceholder() => Container(
      color: Colors.black12,
      child: const Icon(Icons.videocam, size: 32, color: Colors.grey),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProofMediaViewerPage(
              mediaItems: allMedia,
              initialIndex: index,
              orderNumber: _order?.subOrderNumber,
            ),
          ),
        );
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The backing layer. It is first in the stack so the play
                  // button below always paints on top of it.
                  if (!isVideo)
                    CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else if (hasThumbnail)
                    // Filled rather than fitted: the thumbnail is backing for
                    // the play button, so it should cover the tile instead of
                    // sitting in letterbox bars.
                    CachedNetworkImage(
                      imageUrl: thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => videoPlaceholder(),
                    )
                  else
                    videoPlaceholder(),
                  if (isVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            setState(() {});
            _controller.play();
          })
          .catchError((e) {
            setState(() {
              _isError = true;
            });
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text(
          "Failed to load video",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Center(
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
