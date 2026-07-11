import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/order_response_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';

class TrackDonationPage extends StatefulWidget {
  final String orderId;
  final bool autoOpenProofs;

  const TrackDonationPage({
    super.key, 
    required this.orderId,
    this.autoOpenProofs = false,
  });

  @override
  State<TrackDonationPage> createState() => _TrackDonationPageState();
}

class _TrackDonationPageState extends State<TrackDonationPage> {
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
        
        if (widget.autoOpenProofs && _order?.deliveryProof != null && _order!.deliveryProof!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showProofsBottomSheet(context, _order!.deliveryProof!);
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              response.data['message'] ??
              AppLocalizations.of(context)!.error_loading_order_details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        )!.error_occurred_loading_order;
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
              subtitle: _order?.subOrderNumber ?? "  ",
              showBackButton: true,
              onBackTap: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Container(
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
        padding: const EdgeInsets.all(24.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
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
                _errorMessage ?? AppLocalizations.of(context)!.error_title,
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

    final order = _order!;

    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(order),
          const SizedBox(height: 16),
          if (order.target != null) _buildDeliveringToCard(order, isAr),
          const SizedBox(height: 16),
          _buildDeliveryProgressCard(order),
          _buildDeliveryProofs(order),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderResponseModel order) {
    IconData statusIcon = Icons.pending_actions;
    Color statusColor = Colors.orange;

    if (order.status == 'CONFIRMED') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (order.status == 'DISPATCHED' ||
        order.status == 'DELIVERED' ||
        order.status == 'OUT_FOR_DELIVERY') {
      statusIcon = Icons.local_shipping;
      statusColor = Colors.blue;
    }

    String localizedStatus = order.status.replaceAll('_', ' ');
    if (order.status == 'PENDING') {
      localizedStatus = AppLocalizations.of(context)!.order_placed;
    } else if (order.status == 'ASSIGNED' || order.status == 'DELIVERED') {
      localizedStatus = AppLocalizations.of(context)!.out_for_delivery;
    } else if (order.status == 'CONFIRMED') {
      localizedStatus = AppLocalizations.of(context)!.delivered;
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.current_status,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedStatus,
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
                  Text(
                    AppLocalizations.of(context)!.delivering_to,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildDeliveryProgressCard(OrderResponseModel order) {
    final bool isOrderPlaced = true;
    final bool isOutForDelivery =
        order.driver != null ||
        order.status == 'DISPATCHED' ||
        order.status == 'OUT_FOR_DELIVERY' ||
        order.status == 'DELIVERED';
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
              date: order.assignedAt,
              isReached: isOutForDelivery,
              isLast: false,
              icon: Icons.local_shipping,
            ),
            _buildTimelineItem(
              title: AppLocalizations.of(context)!.delivery_completed,
              date: order.completedAt,
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
      final locale = Localizations.localeOf(context).languageCode;
      formattedDate = DateFormat(
        'MMM dd, yyyy - hh:mm a',
        locale,
      ).format(date.toLocal());
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

  Widget _buildDeliveryProofs(OrderResponseModel order) {
    if (order.deliveryProof == null || order.deliveryProof!.isEmpty) {
      return const SizedBox.shrink();
    }

    final proofs = order.deliveryProof!;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _showProofsBottomSheet(context, proofs),
              child: Text(
                AppLocalizations.of(context)!.proof_of_delivery,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProofsBottomSheet(
    BuildContext context,
    Map<String, dynamic> proofs,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                        AppLocalizations.of(context)!.proof_of_delivery,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.tap_to_view,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: [
                  if (proofs['mosqueFrontImage'] != null)
                    _buildSmallProofCard(
                      AppLocalizations.of(context)!.mosque_front,
                      proofs['mosqueFrontImage'],
                      false,
                    ),
                  if (proofs['mosqueInsideImage'] != null)
                    _buildSmallProofCard(
                      AppLocalizations.of(context)!.mosque_inside,
                      proofs['mosqueInsideImage'],
                      false,
                    ),
                  if (proofs['packagesImage'] != null)
                    _buildSmallProofCard(
                      AppLocalizations.of(context)!.packages,
                      proofs['packagesImage'],
                      false,
                    ),
                  if (proofs['deliveryVideo'] != null)
                    _buildSmallProofCard(
                      AppLocalizations.of(context)!.delivery_video,
                      proofs['deliveryVideo'],
                      true,
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  if (isVideo)
                    const Center(
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                top: 0,
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
                top: 0,
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
