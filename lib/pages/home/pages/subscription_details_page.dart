import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/subscription_details_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raheeq_main/pages/home/pages/track_subscription_delivery_page.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailsPage({super.key, required this.subscriptionId});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  SubscriptionDetailsModel? _details;

  List<dynamic> get _allGiftCards {
    if (_details == null) return [];
    final list = <dynamic>[];
    if (_details!.giftCards.isNotEmpty) {
      list.addAll(_details!.giftCards);
    }
    for (var delivery in _details!.deliveries) {
      for (var sub in delivery.subOrders) {
        if (sub.giftCard != null) {
          list.add(sub.giftCard);
        }
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getSubscriptionDetails(
        widget.subscriptionId,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _details = SubscriptionDetailsModel.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatPaymentMethod(BuildContext context, String method) {
    if (method.isEmpty) return '';
    final loc = AppLocalizations.of(context)!;
    switch (method.toUpperCase()) {
      case 'CREDIT_CARD':
      case 'MADA':
        return loc.credit_card_mada;
      case 'STC_PAY':
        return loc.stc_pay;
      case 'APPLE_PAY':
        return loc.apple_pay;
      case 'BANK_TRANSFER':
      case 'IBAN':
        return loc.iban_bank_transfer;
      default:
        final parts = method.split('_');
        return parts
            .map(
              (p) => p.isEmpty
                  ? ''
                  : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.subscription_details;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        color: AppColors.buttonBlueDark,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: title,
                subtitle: _details?.subscriptionNumber ?? '',
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  border: Border.all(color: AppColors.buttonBlueDark, width: 0),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(style: BorderStyle.none, width: 0),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _fetchDetails,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (_details == null) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(AppLocalizations.of(context)!.no_details_found),
      );
    }

    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(isAr),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.deliveries,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonBlueDark,
            ),
          ),
          const SizedBox(height: 12),
          if (_details!.deliveries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.no_deliveries_found,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ..._details!.deliveries.map(
              (delivery) => _buildDeliveryCard(delivery, isAr),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      key: const ValueKey('loader'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 100, height: 20, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isAr) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('MMM dd, yyyy', locale);
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (_details!.planImage.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _details!.planImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? _details!.planNameAr : _details!.planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _localizeFrequency(_details!.frequency),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(
              AppLocalizations.of(context)!.payment_method,
              _formatPaymentMethod(context, _details!.paymentMethod),
            ),

            const SizedBox(height: 8),
            _buildDetailRow(
              AppLocalizations.of(context)!.start_date,
              dateFormat.format(_details!.startDate.toLocal()),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              AppLocalizations.of(context)!.end_date,
              dateFormat.format(_details!.endDate.toLocal()),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              AppLocalizations.of(context)!.total_orders,
              _details!.deliveries.length.toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              AppLocalizations.of(context)!.total_amount,
              '\u202A${AppLocalizations.of(context)!.sar_currency} ${_details!.totalAmount}\u202C',
              isBold: true,
            ),
            if (_details!.invoiceUrl != null &&
                _details!.invoiceUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final url = Uri.parse(_details!.invoiceUrl!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        CustomSnackbar.show(
                          context: context,
                          message: AppLocalizations.of(
                            context,
                          )!.could_not_open_invoice,
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.receipt,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.view_invoice,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
            if (_allGiftCards.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () =>
                      _showGiftCardsBottomSheet(context, _allGiftCards),
                  icon: const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.show_gift_cards,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(SubscriptionDeliveryModel delivery, bool isAr) {
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackSubscriptionDeliveryPage(
              orderId: delivery.orderId,
              subOrderId: delivery.subOrders.isNotEmpty
                  ? delivery.subOrders.first.id
                  : "",
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${delivery.orderNumber}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: AppColors.buttonBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              delivery.scheduledDate != null
                                  ? dateFormat.format(
                                      delivery.scheduledDate!.toLocal(),
                                    )
                                  : dateFormat.format(
                                      delivery.createdAt.toLocal(),
                                    ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubOrder(
    SubscriptionSubOrderModel subOrder,
    bool isAr,
    String orderId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (subOrder.product != null &&
              subOrder.product!.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                subOrder.product!.image,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subOrder.product != null)
                  Text(
                    '${subOrder.product!.quantity}x ${isAr ? subOrder.product!.nameAr : subOrder.product!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.buttonBlueDark,
                    ),
                  ),
                if (subOrder.target != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isAr
                              ? subOrder.target!.labelAr
                              : subOrder.target!.label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(subOrder.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _localizeStatus(subOrder.status, context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(subOrder.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
        return Colors.orange;
      case 'DISPATCHED':
      case 'OUT_FOR_DELIVERY':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _localizeFrequency(String frequency) {
    final freq = frequency.toLowerCase().trim();
    if (freq == 'everyday') {
      return AppLocalizations.of(context)!.everyday;
    } else if (freq == 'once_a_week') {
      return AppLocalizations.of(context)!.once_a_week;
    } else if (freq == 'once_a_month') {
      return AppLocalizations.of(context)!.once_a_month;
    } else if (freq == 'twice_a_week') {
      return AppLocalizations.of(context)!.twice_a_week;
    } else if (freq == 'custom') {
      return AppLocalizations.of(context)!.custom;
    }
    return frequency;
  }

  String _localizeStatus(String status, BuildContext context) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'active') {
      return AppLocalizations.of(context)!.status_active;
    }
    if (lowerStatus == 'cancelled') {
      return AppLocalizations.of(context)!.status_cancelled;
    }
    if (lowerStatus == 'expired') {
      return AppLocalizations.of(context)!.status_expired;
    }
    if (lowerStatus == 'pending') {
      return AppLocalizations.of(context)!.status_pending;
    }

    return status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1).toLowerCase()
        : '';
  }

  void _showGiftCardsBottomSheet(
    BuildContext context,
    List<dynamic> giftCards,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.added_gift_cards,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonBlueDark,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: giftCards.length == 1 ? 300 : 250,
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: giftCards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final giftCard = giftCards[index];
                    final String? imageUrl = giftCard is Map
                        ? giftCard['generatedImage']
                        : null;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: giftCards.length == 1
                            ? MediaQuery.of(context).size.width - 48
                            : 200,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
