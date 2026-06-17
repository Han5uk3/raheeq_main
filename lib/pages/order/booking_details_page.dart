import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookingDetailsPage extends StatefulWidget {
  final String orderId;

  const BookingDetailsPage({super.key, required this.orderId});

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
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading order details.';
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
    final orderPrefix = AppLocalizations.of(context)!.order;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CustomAppBar(
              hasBackgroundColor: true,
              isStartAligned: true,
              title: title,
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
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

  Widget _buildSectionHeader(String title, {required TextStyle style}) {
    return Text(title, style: style);
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.buttonBlueDark),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? "Error",
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: _fetchOrderDetails,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final order = _order!;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());
    final orderPrefix = AppLocalizations.of(context)!.order;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Center(
            child: Column(
              children: [
                Text(
                  '$orderPrefix #${order.subOrderNumber}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonBlueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFEAEFF2), height: 1),
          const SizedBox(height: 24),

          // Product details
          if (order.product != null) ...[
            _buildSectionHeader(
              AppLocalizations.of(context)!.product_details,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order.product!.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
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
                        isAr ? order.product!.nameAr : order.product!.name,
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
            const SizedBox(height: 24),
          ],

          // Target details
          if (order.target != null) ...[
            const Divider(color: Color(0xFFEAEFF2), height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              AppLocalizations.of(context)!.location_details,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order.target!.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? order.target!.labelAr : order.target!.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.target!.type,
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
            const SizedBox(height: 24),
          ],

          // Financials
          if (order.financials != null) ...[
            const Divider(color: Color(0xFFEAEFF2), height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader(
              AppLocalizations.of(context)!.financial_details,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              AppLocalizations.of(context)!.amount_value,
              order.financials!.amount,
              isAr,
            ),
            const SizedBox(height: 12),
            _buildFinancialRow(
              AppLocalizations.of(context)!.delivery_fee,
              order.financials!.deliveryFee,
              isAr,
            ),
            const SizedBox(height: 12),
            _buildFinancialRow(
              AppLocalizations.of(context)!.vat,
              order.financials!.vatAmount,
              isAr,
            ),
            const SizedBox(height: 16),
            _buildFinancialRow(
              AppLocalizations.of(context)!.total_amount,
              order.financials!.totalAmount,
              isAr,
              isTotal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount,
    bool isAr, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.buttonBlueDark : Colors.grey[700],
          ),
        ),
        Text(
          '$amount ${AppLocalizations.of(context)!.sar_currency}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.buttonBlue : Colors.black,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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
