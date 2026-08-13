import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/utils/formatters.dart';

class TrackSubscriptionDeliveryPage extends StatefulWidget {
  final String orderId;
  final String subOrderId;

  const TrackSubscriptionDeliveryPage({
    super.key,
    required this.orderId,
    required this.subOrderId,
  });

  @override
  State<TrackSubscriptionDeliveryPage> createState() =>
      _TrackSubscriptionDeliveryPageState();
}

class _TrackSubscriptionDeliveryPageState
    extends State<TrackSubscriptionDeliveryPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OrderResponseModel> _subOrders = [];

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
      final response = await ApiService().getSubOrderDetails(widget.orderId);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List?;
        if (data != null) {
          setState(() {
            _subOrders = data
                .map((e) => OrderResponseModel.fromJson(e))
                .where(
                  (e) => widget.subOrderId.isEmpty || e.id == widget.subOrderId,
                )
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _subOrders = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load sub orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = AppLocalizations.of(context)!.error;
      if (e.toString().contains('connection error')) {
        errorMessage = AppLocalizations.of(context)!.internet_error;
      } else if (e is DioException &&
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
    String title = AppLocalizations.of(context)!.track_donation;
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
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark,
                border: Border.all(color: AppColors.buttonBlueDark, width: 0),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 150,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFB),
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
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAr) {
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
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 16),
              Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const Divider(height: 48),

              const SizedBox(height: 24),
              Container(height: 20, width: 150, color: Colors.white),
              const SizedBox(height: 16),
              Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 82,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
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

    if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? "Error",
                style: const TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: _fetchOrderDetails,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_subOrders.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(
          AppLocalizations.of(context)!.no_deliveries_found_for_this_order,
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subOrders.length,
            itemBuilder: (context, index) {
              final order = _subOrders[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${order.subOrderNumber}",
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.buttonBlueDark,
                    ),
                  ),

                  if (order.target != null) _buildDeliveringToCard(order, isAr),
                  if (order.product != null) ...[
                    _buildProductCard(order, isAr),
                  ],

                  if (order.deliveredToDifferentMosque == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
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

                  _buildDeliveryProgressCard(order),

                  if (order.status == 'COMPLETED' ||
                      order.status == 'DELIVERED') ...[
                    _buildActionButtons(order),
                    const SizedBox(height: 16),
                    _buildDeliveryProofs(order),
                  ],

                  if (index < _subOrders.length - 1) const Divider(height: 48),
                  if (index == _subOrders.length - 1)
                    const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveringToCard(OrderResponseModel order, bool isAr) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: order.target!.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
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
                  const Text(
                    "Delivering to",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? order.target!.labelAr : order.target!.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(OrderResponseModel order, bool isAr) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: order.product!.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 50,
                  height: 50,
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
                    AppLocalizations.of(context)!.product,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? order.product!.nameAr : order.product!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (order.product!.quantity > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'x${order.product!.quantity}',
                  style: const TextStyle(
                    color: AppColors.buttonBlueDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
              date: order.confirmedAt ?? order.completedAt,
              isReached: isDelivered,
              isLast: true,
              icon: Icons.check_circle,
            ),
          ],
        ),
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
      formattedDate = Formatters.formatDateTime(context, date);
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

  Widget _buildActionButtons(OrderResponseModel order) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.buttonBlueDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          // Scroll to proofs or nothing, as proofs are below.
        },
        icon: const Icon(
          Icons.photo_library,
          color: AppColors.buttonBlueDark,
          size: 18,
        ),
        label: const Text(
          "Proof of Delivery",
          style: TextStyle(color: AppColors.buttonBlueDark, fontSize: 12),
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

    // Some proofs from subscription tracking use 'proofVideo' or 'video' occasionally as seen in the original code, but 'deliveryVideo' is standard
    final deliveryVideo =
        proofs['deliveryVideo'] ?? proofs['proofVideo'] ?? proofs['video'];
    if (deliveryVideo != null && deliveryVideo.toString().isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          AppLocalizations.of(context)!.delivery_video,
          deliveryVideo,
          true,
        ),
      );
    }

    if (proofItems.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
      ),
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
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
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
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
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
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
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
