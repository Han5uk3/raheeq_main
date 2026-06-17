import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OrderResponseModel> _newOrders = [];
  List<OrderResponseModel> _outForDelivery = [];
  List<OrderResponseModel> _delivered = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getMyOrders();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['items'] as List;
        final orders = data
            .map((json) => OrderResponseModel.fromJson(json))
            .toList();

        setState(() {
          _newOrders = orders
              .where((o) => o.status == 'PENDING' || o.status == 'PROCESSING')
              .toList();
          _outForDelivery = orders
              .where(
                (o) =>
                    o.status == 'DISPATCHED' || o.status == 'OUT_FOR_DELIVERY',
              )
              .toList();
          _delivered = orders.where((o) => o.status == 'DELIVERED').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading orders.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                splashFactory: NoSplash.splashFactory,
                splashBorderRadius: BorderRadius.circular(25),
                isScrollable: false,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.buttonBlueDark,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.buttonBlueDark,
                ),
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.new_orders,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Tab(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.out_for_delivery,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Tab(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.delivered,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
            TextButton(
              onPressed: _fetchOrders,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      children: [
        _buildOrdersList(
          _newOrders,
          AppLocalizations.of(context)!.no_new_orders,
        ),
        _buildOrdersList(
          _outForDelivery,
          AppLocalizations.of(context)!.no_orders_out_for_delivery,
        ),
        _buildOrdersList(
          _delivered,
          AppLocalizations.of(context)!.no_delivered_orders,
        ),
      ],
    );
  }

  Widget _buildOrdersList(
    List<OrderResponseModel> orders,
    String emptyMessage,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppColors.buttonBlue,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderResponseModel order) {
    return _OrderCard(order: order);
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

class _OrderCard extends StatefulWidget {
  final OrderResponseModel order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final orderDate = widget.order.createdAt.toLocal();
    final formattedDate = dateFormat.format(orderDate);
    final formattedTime = timeFormat.format(orderDate);

    final String imageUrl =
        widget.order.product?.image ?? widget.order.target?.image ?? '';

    String locationTitle = '';
    if (widget.order.target != null && widget.order.target!.label.isNotEmpty) {
      locationTitle = isAr
          ? widget.order.target!.labelAr
          : widget.order.target!.label;
    } else if (widget.order.product != null) {
      locationTitle = isAr
          ? widget.order.product!.nameAr
          : widget.order.product!.name;
    }

    final String address =
        widget.order.locationDetails != null &&
            widget.order.locationDetails!['address'] != null
        ? widget.order.locationDetails!['address'].toString()
        : '';

    final String totalCost =
        '${widget.order.totalAmount} ${AppLocalizations.of(context)!.sar_currency}';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              width: 60,
                              height: 60,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          totalCost,
                          style: const TextStyle(
                            color: AppColors.buttonBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.date,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.time,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonBlueDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Placeholder for track order
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.track_order,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.buttonBlueDark,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookingDetailsPage(
                                              orderId: widget.order.id,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.view_receipt,
                                    style: const TextStyle(
                                      color: AppColors.buttonBlueDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.grey,
                          ),
                        ],
                      )
                    : const SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            SizedBox(height: 12),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
