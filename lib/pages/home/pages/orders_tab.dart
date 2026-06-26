import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:raheeq_main/pages/order/track_donation_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastFetchedIndex = 0;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  List<OrderResponseModel> _newOrders = [];
  List<OrderResponseModel> _outForDelivery = [];
  List<OrderResponseModel> _delivered = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchOrders();
    _scrollController.addListener(_scrollListener);
  }

  void _handleTabSelection() {
    if (_tabController.index != _lastFetchedIndex) {
      _lastFetchedIndex = _tabController.index;
      _fetchOrders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreOrders();
    }
  }

  String _getTabName() {
    if (_tabController.index == 0) return 'upcoming';
    if (_tabController.index == 1) return 'out_for_delivery';
    return 'delivered';
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      if (_tabController.index == 0)
        _newOrders.clear();
      else if (_tabController.index == 1)
        _outForDelivery.clear();
      else
        _delivered.clear();
    });

    try {
      final response = await ApiService().getMyOrders(
        page: _currentPage,
        tab: _getTabName(),
      );
      _processOrdersResponse(response);
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading orders.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final response = await ApiService().getMyOrders(
        page: _currentPage,
        tab: _getTabName(),
      );
      _processOrdersResponse(response);
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _processOrdersResponse(dynamic response) {
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data']['items'] as List;
      final orders = data
          .map((json) => OrderResponseModel.fromJson(json))
          .toList();
      final int totalPages = response.data['data']['totalPages'] ?? 1;

      setState(() {
        if (_tabController.index == 0) {
          _newOrders.addAll(orders);
        } else if (_tabController.index == 1) {
          _outForDelivery.addAll(orders);
        } else {
          _delivered.addAll(orders);
        }

        _hasMore = _currentPage < totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        if (_currentPage == 1) {
          _errorMessage = response.data['message'] ?? 'Failed to load orders';
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppColors.buttonBlue,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            CustomAppBar(
              title: AppLocalizations.of(context)!.my_orders,
              subtitle: AppLocalizations.of(context)!.track_your_donations,
              centerTitle: true,
            ),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 150,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E9EC),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
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
                  AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      if (tabController.index == 0) {
                        return _buildOrdersList(
                          _newOrders,
                          AppLocalizations.of(context)!.no_new_orders,
                          false,
                        );
                      } else if (tabController.index == 1) {
                        return _buildOrdersList(
                          _outForDelivery,
                          AppLocalizations.of(
                            context,
                          )!.no_orders_out_for_delivery,
                          false,
                        );
                      } else {
                        return _buildOrdersList(
                          _delivered,
                          AppLocalizations.of(context)!.no_delivered_orders,
                          true,
                        );
                      }
                    },
                  ),
                  if (_isLoadingMore)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 35,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 16,
                                          width: double.infinity,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 14,
                                          width: 150,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 16,
                                          width: 80,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 145), // Padding at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    List<OrderResponseModel> orders,
    String emptyMessage,
    bool isDelivered,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      child: _buildOrdersListInternal(orders, emptyMessage, isDelivered),
    );
  }

  Widget _buildOrdersListInternal(
    List<OrderResponseModel> orders,
    String emptyMessage,
    bool isDelivered,
  ) {
    if (_isLoading) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            key: const ValueKey('loader'),
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 35,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 150,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(height: 16, width: 80, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (_errorMessage != null) {
      return Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: _fetchOrders,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      final availableHeight = MediaQuery.of(context).size.height - 377;
      return Container(
        key: const ValueKey('empty'),
        height: availableHeight > 200 ? availableHeight : 200,
        alignment: Alignment.center,
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      key: const ValueKey('content'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isDelivered);
      },
    );
  }

  Widget _buildOrderCard(OrderResponseModel order, bool isDelivered) {
    return _OrderCard(
      order: order,
      isDelivered: isDelivered,
      onRefresh: _fetchOrders,
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderResponseModel order;
  final bool isDelivered;
  final VoidCallback onRefresh;

  const _OrderCard({
    required this.order,
    required this.isDelivered,
    required this.onRefresh,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  String _formatTargetType(OrderTarget target, bool isAr) {
    if (target.type.isEmpty) return '';
    final lowerType = target.type.toLowerCase();

    if (isAr) {
      switch (lowerType) {
        case 'category':
          return 'فئة';
        case 'campaign':
          return 'حملة';
        case 'location':
          return 'موقع';
        default:
          return target.type;
      }
    } else {
      switch (lowerType) {
        case 'category':
          return 'Category';
        case 'campaign':
          return 'Campaign';
        case 'location':
          return 'Location';
        default:
          return target.type[0].toUpperCase() +
              target.type.substring(1).toLowerCase();
      }
    }
  }

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
        '\u202A${AppLocalizations.of(context)!.sar_currency} ${widget.order.totalAmount}\u202C';

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingDetailsPage(orderId: widget.order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${widget.order.subOrderNumber}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (widget.order.target?.type != null &&
                      widget.order.target!.type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTargetType(widget.order.target!, isAr),
                        style: const TextStyle(
                          color: AppColors.buttonBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(),
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
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.white,
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
                        const SizedBox(height: 4),

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalCost,
                              style: const TextStyle(
                                color: AppColors.buttonBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.isDelivered &&
                                widget.order.review == null)
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonBlueDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    _showRateOrderBottomSheet(
                                      context,
                                      widget.order.id,
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.rate_order,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrackDonationPage(
                                          orderId: widget.order.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.track_donation,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              if (widget.order.invoiceUrl != null &&
                                  widget.order.invoiceUrl!.isNotEmpty) ...[
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
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        widget.order.invoiceUrl!,
                                      );
                                      try {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (e) {
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
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.view_receipt,
                                      style: const TextStyle(
                                        color: AppColors.buttonBlueDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _isExpanded = false;
                              });
                            },
                            child: const SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _isExpanded = true;
                          });
                        },
                        child: const SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              SizedBox(height: 4),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateOrderBottomSheet(BuildContext context, String orderId) {
    int rating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.rate_order_title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              AppLocalizations.of(
                                context,
                              )!.how_was_your_experience,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.write_review,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.buttonBlue,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setState(() {
                                  isSubmitting = true;
                                });
                                try {
                                  final response = await ApiService().rateOrder(
                                    orderId,
                                    rating,
                                    reviewController.text.trim(),
                                  );
                                  if (response.statusCode == 200 ||
                                      response.statusCode == 201) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      CustomSnackbar.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.review_submitted,
                                      );
                                      widget.onRefresh();
                                    }
                                  } else {
                                    if (context.mounted) {
                                      CustomSnackbar.show(
                                        context: context,
                                        message:
                                            response.data['message'] ??
                                            'Failed to submit review',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    CustomSnackbar.show(
                                      context: context,
                                      message: 'Failed to submit review',
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.submit_review,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
