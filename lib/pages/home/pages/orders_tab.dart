import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:raheeq_main/pages/order/booking_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/services/deep_link_service.dart';
import 'package:video_player/video_player.dart';

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
      if (_tabController.index == 0) {
        _newOrders.clear();
      } else if (_tabController.index == 1) {
        _outForDelivery.clear();
      } else {
        _delivered.clear();
      }
    });

    try {
      final response = await ApiService().getMyOrders(
        page: _currentPage,
        tab: _getTabName(),
      );
      _processOrdersResponse(response);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
                    const SizedBox(height: 145), // Padding at the bottom
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
                onPressed: _fetchOrders,
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
                  if (widget.order.status.toUpperCase() == 'COMPLETED')
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          DeepLinkService().handleReorder(widget.order.id);
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.reorder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
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
                          Text(
                            address,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalCost,
                              style: const TextStyle(
                                color: AppColors.buttonBlueDark,
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
              const SizedBox(height: 12),
              const Divider(),
              _buildDeliveryProofs(widget.order),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.date,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
              if (widget.order.invoiceUrl != null &&
                  widget.order.invoiceUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.buttonBlueDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      style: const TextStyle(color: AppColors.buttonBlueDark),
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
    List<Widget> proofItems = [];

    if (proofs['mosqueFrontImage'] != null &&
        proofs['mosqueFrontImage'].toString().isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          AppLocalizations.of(context)!.mosque_front,
          proofs['mosqueFrontImage'],
          false,
        ),
      );
    }
    if (proofs['mosqueInsideImage'] != null &&
        proofs['mosqueInsideImage'].toString().isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          AppLocalizations.of(context)!.mosque_inside,
          proofs['mosqueInsideImage'],
          false,
        ),
      );
    }
    if (proofs['packagesImage'] != null &&
        proofs['packagesImage'].toString().isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          AppLocalizations.of(context)!.packages,
          proofs['packagesImage'],
          false,
        ),
      );
    }
    if (proofs['deliveryVideo'] != null &&
        proofs['deliveryVideo'].toString().isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          AppLocalizations.of(context)!.delivery_video,
          proofs['deliveryVideo'],
          true,
        ),
      );
    }

    if (proofItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.proof_of_delivery,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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
        const Divider(),
      ],
    );
  }

  Widget _buildSmallProofCard(String title, String url, bool isVideo) {
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _showVideoPreview(url);
        } else {
          _showImagePreview(url);
        }
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
                  if (!isVideo)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
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
                  else
                    Container(
                      color: Colors.black12,
                      child: const Icon(
                        Icons.videocam,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  if (isVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoPreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoPlayerWidget(url: url),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
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
              ),
            ],
          ),
        );
      },
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
