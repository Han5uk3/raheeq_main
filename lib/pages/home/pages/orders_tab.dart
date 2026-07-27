import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/services/snackbar_insets_services.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:raheeq_main/pages/order/proof_media_viewer_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:video_player/video_player.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  /// Write a tab index to this notifier to switch the inner tab remotely.
  static final ValueNotifier<int?> switchInnerTabNotifier = ValueNotifier(null);

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastFetchedIndex = 0;

  static bool _hasLoadedOnce = false;

  static List<OrderResponseModel> _cachedUpcomingOrders = [];
  static List<OrderResponseModel> _cachedOutForDeliveryOrders = [];
  static List<OrderResponseModel> _cachedDeliveredOrders = [];
  static List<bool> _cachedHasMore = [true, true, true];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  late List<OrderResponseModel> _newOrders;
  late List<OrderResponseModel> _outForDelivery;
  late List<OrderResponseModel> _delivered;

  List<int> _currentPages = [1, 1, 1];
  late List<bool> _hasMoreList;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SnackbarInsets.setBottomInset(kBottomNavigationBarHeight + 10);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    OrdersTab.switchInnerTabNotifier.addListener(_onSwitchInnerTab);
    _onSwitchInnerTab();

    _newOrders = List.from(_cachedUpcomingOrders);
    _outForDelivery = List.from(_cachedOutForDeliveryOrders);
    _delivered = List.from(_cachedDeliveredOrders);
    _hasMoreList = List.from(_cachedHasMore);

    if (_hasLoadedOnce) {
      _isLoading = false;
    }

    _scrollController.addListener(_scrollListener);

    // Always update them when page is opened
    _fetchAllOrders();
  }

  void _handleTabSelection() {
    if (_tabController.index != _lastFetchedIndex) {
      setState(() {
        _lastFetchedIndex = _tabController.index;
      });
    }
  }

  void _onSwitchInnerTab() {
    final idx = OrdersTab.switchInnerTabNotifier.value;
    if (idx != null) {
      if (mounted) {
        _tabController.index = idx;
      }
      OrdersTab.switchInnerTabNotifier.value = null;
    }
  }

  @override
  void dispose() {
    OrdersTab.switchInnerTabNotifier.removeListener(_onSwitchInnerTab);
    _tabController.dispose();
    SnackbarInsets.clear();

    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMoreList[_tabController.index]) {
      _loadMoreOrders();
    }
  }

  String _getTabName() {
    if (_tabController.index == 0) return 'upcoming';
    if (_tabController.index == 1) return 'out_for_delivery';
    return 'delivered';
  }

  Future<void> _fetchAllOrders() async {
    if (!mounted) return;
    setState(() {
      if (!_hasLoadedOnce) _isLoading = true;
      _errorMessage = null;
      _currentPages = [1, 1, 1];
    });

    try {
      final upcomingFuture = ApiService().getMyOrders(page: 1, tab: 'upcoming');
      final outForDeliveryFuture = ApiService().getMyOrders(
        page: 1,
        tab: 'out_for_delivery',
      );
      final deliveredFuture = ApiService().getMyOrders(
        page: 1,
        tab: 'delivered',
      );

      final responses = await Future.wait([
        upcomingFuture,
        outForDeliveryFuture,
        deliveredFuture,
      ]);

      _processInitialResponse(0, responses[0], 'upcoming');
      _processInitialResponse(1, responses[1], 'out_for_delivery');
      _processInitialResponse(2, responses[2], 'delivered');

      _hasLoadedOnce = true;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('connection error')) {
            _errorMessage = AppLocalizations.of(context)!.internet_error;
          } else if (e is DioException) {
            _errorMessage =
                e.response?.data['message'] ??
                AppLocalizations.of(context)!.failed_to_load_orders;
          } else {
            _errorMessage = AppLocalizations.of(context)!.error;
          }
          _isLoading = false;
        });
      }
    }
  }

  void _processInitialResponse(int tabIndex, dynamic response, String tabName) {
    if (tabName == 'delivered') {
      log('Completed orders full response: ${jsonEncode(response.data)}');
    }
    if (tabName == 'upcoming') {
      log('New orders full response: ${jsonEncode(response.data)}');
    }
    if (response.statusCode == 200 && response.data['success'] == true) {
      final data = response.data['data']['items'] as List;
      final orders = data
          .map((json) => OrderResponseModel.fromJson(json))
          .toList();
      final int totalPages = response.data['data']['totalPages'] ?? 1;

      if (tabIndex == 0) {
        _cachedUpcomingOrders = List.from(orders);
        _newOrders = List.from(orders);
      } else if (tabIndex == 1) {
        _cachedOutForDeliveryOrders = List.from(orders);
        _outForDelivery = List.from(orders);
      } else {
        _cachedDeliveredOrders = List.from(orders);
        _delivered = List.from(orders);
      }

      final hasMore = 1 < totalPages;
      _hasMoreList[tabIndex] = hasMore;
      _cachedHasMore[tabIndex] = hasMore;
    }
  }

  Future<void> _loadMoreOrders() async {
    final tabIndex = _tabController.index;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPages[tabIndex]++;
      final response = await ApiService().getMyOrders(
        page: _currentPages[tabIndex],
        tab: _getTabName(),
      );

      if (_getTabName() == 'upcoming') {
        log(
          'New orders full response (page ${_currentPages[tabIndex]}): ${jsonEncode(response.data)}',
        );
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['items'] as List;
        final orders = data
            .map((json) => OrderResponseModel.fromJson(json))
            .toList();
        final int totalPages = response.data['data']['totalPages'] ?? 1;

        if (mounted) {
          setState(() {
            if (tabIndex == 0) {
              _newOrders.addAll(orders);
            } else if (tabIndex == 1) {
              _outForDelivery.addAll(orders);
            } else {
              _delivered.addAll(orders);
            }
            _hasMoreList[tabIndex] = _currentPages[tabIndex] < totalPages;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _currentPages[tabIndex]--;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPages[tabIndex]--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    return RefreshIndicator(
      onRefresh: _fetchAllOrders,
      color: AppColors.buttonBlueDark,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            CustomAppBar(
              hasBackgroundColor: true,

              title: AppLocalizations.of(context)!.my_orders,
              subtitle: AppLocalizations.of(context)!.track_your_donations,
              centerTitle: true,
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark,
                border: Border.all(color: AppColors.buttonBlueDark, width: 0),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(style: BorderStyle.none, width: 0),
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
                                  AppLocalizations.of(
                                    context,
                                  )!.out_for_delivery,
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
                        itemCount: 10,
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
                    const SizedBox(height: 115), // Padding at the bottom
                  ],
                ),
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
      final availableHeight = MediaQuery.of(context).size.height - 377;
      return Container(
        key: const ValueKey('error'),
        height: availableHeight > 200 ? availableHeight : 200,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.failed_to_load_orders_page,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchAllOrders,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                HomeScreen.switchTabNotifier.value = 0;
              },
              child: Text(
                AppLocalizations.of(context)!.order_now,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
      onRefresh: _fetchAllOrders,
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
  // Design-time reference width for the card. This is roughly the card
  // width on a typical phone once the ListView's 16px horizontal padding
  // is subtracted. Anything narrower (small phones, split-screen) or wider
  // (tablets, foldables, landscape, desktop) scales relative to this.
  static const double _baseCardWidth = 380.0;

  // Clamp so text/images never shrink to unreadable sizes or blow up to
  // comically large ones on very wide displays.
  static const double _minScale = 0.85;
  static const double _maxScale = 1.4;

  double _scale = 1.0;

  /// Scales a design-time pixel value (font size, spacing, icon/image
  /// size...) by the current responsive [_scale] for this card instance.
  double _s(double value) => value * _scale;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final dateFormat = DateFormat('MMM dd, yyyy', locale);
    final timeFormat = DateFormat('hh:mm a', locale);
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
          
      if (widget.order.target!.type == 'CAMPAIGN' &&
          widget.order.product != null) {
        final productName = isAr
            ? widget.order.product!.nameAr
            : widget.order.product!.name;
        locationTitle += ' - $productName';
      }
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

    // LayoutBuilder gives us the actual constraints the card is rendered
    // with, which is more reliable than MediaQuery.size for computing the
    // scale factor -- it still works correctly if this card ever ends up
    // inside a grid, a side panel, or a constrained-width container on a
    // tablet, rather than always assuming full screen width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        _scale = (width / _baseCardWidth).clamp(_minScale, _maxScale);

        return _buildOrderCardContent(
          imageUrl,
          locationTitle,
          address,
          formattedDate,
          formattedTime,
          totalCost,
        );
      },
    );
  }

  Widget _buildOrderCardContent(
    String imageUrl,
    String locationTitle,
    String address,
    String formattedDate,
    String formattedTime,
    String totalCost,
  ) {
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
          padding: EdgeInsets.all(_s(16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.order_number,
                    style: TextStyle(fontSize: _s(14)),
                  ),
                  Text(
                    '#${widget.order.subOrderNumber}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: Colors.grey, fontSize: _s(14)),
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
                            width: _s(60),
                            height: _s(60),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: _s(60),
                                height: _s(60),
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              width: _s(60),
                              height: _s(60),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: _s(24),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            width: _s(60),
                            height: _s(60),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey,
                              size: _s(24),
                            ),
                          ),
                  ),
                  SizedBox(width: _s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _s(16),
                          ),
                        ),
                        SizedBox(height: _s(4)),

                        if (address.isNotEmpty) ...[
                          Text(
                            address,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: _s(14),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: _s(4)),
                        ],

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalCost,
                              style: TextStyle(
                                color: AppColors.buttonBlueDark,
                                fontWeight: FontWeight.bold,
                                fontSize: _s(14),
                              ),
                            ),
                            Row(
                              spacing: _s(6),
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (widget.isDelivered &&
                                    widget.order.review == null)
                                  SizedBox(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.buttonBlueDark,
                                        padding: EdgeInsets.symmetric(
                                          vertical: _s(8),
                                          horizontal: _s(12),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        _showRateOrderBottomSheet(
                                          context,
                                          widget.order.id,
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.rate_order,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: _s(11),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (widget.order.status.toUpperCase() ==
                                    'CONFIRMED')
                                  SizedBox(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.buttonBlueDark,
                                        padding: EdgeInsets.symmetric(
                                          vertical: _s(8),
                                          horizontal: _s(12),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        DeepLinkService().handleReorder(
                                          widget.order.id,
                                        );
                                      },

                                      child: Text(
                                        AppLocalizations.of(context)!.reorder,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: _s(11),
                                        ),
                                      ),
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
              SizedBox(height: _s(12)),
              const Divider(),
              _buildDeliveryProofs(widget.order),
              SizedBox(height: _s(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.date,
                    style: TextStyle(color: Colors.grey, fontSize: _s(14)),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.black, fontSize: _s(14)),
                  ),
                ],
              ),
              SizedBox(height: _s(4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.time,
                    style: TextStyle(color: Colors.grey, fontSize: _s(14)),
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(color: Colors.black, fontSize: _s(14)),
                  ),
                ],
              ),
              if (widget.order.invoiceUrl != null &&
                  widget.order.invoiceUrl!.isNotEmpty) ...[
                SizedBox(height: _s(12)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.buttonBlueDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: _s(8)),
                    ),
                    onPressed: () async {
                      final url = Uri.parse(widget.order.invoiceUrl!);
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
                      AppLocalizations.of(context)!.view_receipt,
                      style: TextStyle(
                        color: AppColors.buttonBlueDark,
                        fontSize: _s(13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryProofs(OrderResponseModel order) {
    if (order.deliveryProof == null || order.deliveryProof!.isEmpty) {
      return const SizedBox.shrink();
    }

    final proofs = order.deliveryProof!;
    List<ProofMediaItem> mediaItems = [];

    if (proofs['mosqueFrontImage'] != null &&
        proofs['mosqueFrontImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.mosque_front,
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
          url: proofs['mosqueInsideImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['packagesImage'] != null &&
        proofs['packagesImage'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.packages,
          url: proofs['packagesImage'],
          isVideo: false,
        ),
      );
    }

    if (proofs['deliveryVideo'] != null &&
        proofs['deliveryVideo'].toString().isNotEmpty) {
      mediaItems.add(
        ProofMediaItem(
          title: AppLocalizations.of(context)!.delivery_video,
          url: proofs['deliveryVideo'],
          isVideo: true,
        ),
      );
    }

    if (mediaItems.isEmpty) return const SizedBox.shrink();

    List<Widget> proofItems = [];
    for (int i = 0; i < mediaItems.length; i++) {
      proofItems.add(
        _buildSmallProofCard(
          mediaItems[i].title,
          mediaItems[i].url,
          mediaItems[i].isVideo,
          i,
          mediaItems,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _s(8)),
        Text(
          AppLocalizations.of(context)!.proof_of_delivery,
          style: TextStyle(fontSize: _s(14), fontWeight: FontWeight.bold),
        ),
        SizedBox(height: _s(12)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (index) {
            if (index.isOdd) {
              return SizedBox(width: _s(8.0));
            }
            int itemIndex = index ~/ 2;
            if (itemIndex < proofItems.length) {
              return Expanded(child: proofItems[itemIndex]);
            } else {
              return const Expanded(child: SizedBox.shrink());
            }
          }),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSmallProofCard(
    String title,
    String url,
    bool isVideo,
    int index,
    List<ProofMediaItem> allMedia,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProofMediaViewerPage(mediaItems: allMedia, initialIndex: index),
          ),
        );
      },
      child: Column(
        children: [
          AspectRatio(
            // Kept square regardless of scale so proof thumbnails always
            // line up neatly in the row across screen sizes.
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isVideo)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: _s(24),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black12,
                      child: Icon(
                        Icons.videocam,
                        size: _s(24),
                        color: Colors.grey,
                      ),
                    ),
                  if (isVideo)
                    Center(
                      child: CircleAvatar(
                        radius: _s(12),
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: _s(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: _s(4)),
          Text(
            title,
            style: TextStyle(fontSize: _s(10), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  

  void _showRateOrderBottomSheet(BuildContext context, String orderId) {
    int rating = 0;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              canPop: !isSubmitting,
              child: AbsorbPointer(
                absorbing: isSubmitting,
                child: Container(
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
                                  AppLocalizations.of(
                                    context,
                                  )!.rate_order_title,
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
                          cursorColor: AppColors.buttonBlueDark,
                          style: const TextStyle(
                            color: AppColors.buttonBlueDark,
                            fontSize: 12,
                          ),
                          controller: reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.write_review,
                            hintStyle: TextStyle(
                              color: AppColors.buttonBlueDark.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.buttonBlueDark,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.buttonBlueDark,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.buttonBlueDark,
                                width: 1.5,
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
                                      final response = await ApiService()
                                          .rateOrder(
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
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: WaterLoadingIndicator(
                                      size: 20,
                                      waveColor1: Colors.white,
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
                ),
              ),
            );
          },
        );
      },
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
