import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/subscription_details_model.dart';
import 'package:intl/intl.dart';

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
        _errorMessage = 'An error occurred while loading details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.subscription_details;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: _details?.subscriptionNumber ?? '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildContent(isAr),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.buttonBlueDark),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _fetchDetails, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_details == null) {
      return const Center(child: Text("No details found."));
    }

    return RefreshIndicator(
      onRefresh: _fetchDetails,
      color: AppColors.buttonBlue,
      child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildInfoCard(bool isAr) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
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
                        _details!.frequency,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // _buildDetailRow(
            //   AppLocalizations.of(context)!.purchased_date,
            //   dateFormat.format(_details!..toLocal()),
            // ),
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
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          '${AppLocalizations.of(context)!.order} #${delivery.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          delivery.scheduledDate != null
              ? '${AppLocalizations.of(context)!.scheduled}: ${dateFormat.format(delivery.scheduledDate!.toLocal())}'
              : '${AppLocalizations.of(context)!.created}: ${dateFormat.format(delivery.createdAt.toLocal())}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: delivery.subOrders
            .map((subOrder) => _buildSubOrder(subOrder, isAr))
            .toList(),
      ),
    );
  }

  Widget _buildSubOrder(SubscriptionSubOrderModel subOrder, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (subOrder.product != null &&
              subOrder.product!.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                subOrder.product!.image,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subOrder.product != null)
                  Text(
                    '${subOrder.product!.quantity}x ${isAr ? subOrder.product!.nameAr : subOrder.product!.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (subOrder.target != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
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
                            fontSize: 12,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u202A${AppLocalizations.of(context)!.sar_currency} ${subOrder.totalAmount}\u202C',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonBlue,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    subOrder.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subOrder.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(subOrder.status),
                  ),
                ),
              ),
            ],
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
}
