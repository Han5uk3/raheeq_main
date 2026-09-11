import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/chiller_model.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';
import 'package:raheeq_main/utils/chiller_refill_target.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'dart:developer';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/widgets/order_chiller_sheet.dart';
import 'package:raheeq_main/pages/home/pages/chiller_details_page.dart';

class MyChillersPage extends StatefulWidget {
  const MyChillersPage({super.key});

  @override
  State<MyChillersPage> createState() => _MyChillersPageState();
}

class _MyChillersPageState extends State<MyChillersPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ChillerModel> _chillers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchChillers();
  }

  Future<void> _fetchChillers() async {
    try {
      final response = await _apiService.getMyChillers();
      log('My Chillers API Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _chillers = data.map((e) => ChillerModel.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error fetching chillers: $e');
      if (!mounted) return;
      if (e.toString().contains('connection error')) {
        _errorMessage = AppLocalizations.of(context)!.internet_error;
      } else if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = AppLocalizations.of(context)!.error;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 12, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only live chillers are listed. Whether each one can also be refilled is a
    // separate question the card answers for itself.
    final visibleChillers = _chillers.where((c) => c.isActive).toList();

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonBlueDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => OrderChillerSheet.start(context),
            child: Text(
              AppLocalizations.of(context)!.order_new_chiller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: AppLocalizations.of(context)!.my_chillers,
            subtitle: AppLocalizations.of(context)!.my_chillers_subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: Container(
                color: AppColors.buttonBlueDark,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: <Widget>[
                                ...previousChildren,
                                ?currentChild,
                              ],
                            );
                          },
                          child: _isLoading
                              ? _buildShimmerLoading()
                              : visibleChillers.isEmpty
                              ? Center(
                                  key: const ValueKey('empty'),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.no_chillers_found,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('content'),
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    left: 16,
                                    right: 16,
                                    bottom: 60,
                                  ),
                                  itemCount: visibleChillers.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _buildChillerItem(
                                        visibleChillers[index],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChillerItem(ChillerModel chiller) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final productName = isArabic
        ? (chiller.product?.nameAr.isNotEmpty == true
              ? chiller.product!.nameAr
              : chiller.product?.name ?? '')
        : (chiller.product?.name.isNotEmpty == true
              ? chiller.product!.name
              : chiller.product?.nameAr ?? '');
    final locationName = isArabic
        ? (chiller.deliveredLocation?.nameAr.isNotEmpty == true
              ? chiller.deliveredLocation!.nameAr
              : chiller.deliveredLocation?.name ?? '')
        : (chiller.deliveredLocation?.name.isNotEmpty == true
              ? chiller.deliveredLocation!.name
              : chiller.deliveredLocation?.nameAr ?? '');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChillerDetailsPage(chiller: chiller),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chiller.product?.image != null &&
                    chiller.product!.image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: chiller.product!.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color.fromRGBO(245, 245, 245, 1),
                        highlightColor: const Color.fromRGBO(245, 245, 245, 1),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(245, 245, 245, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.order_number}:',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          Text(
                            ' ${chiller.subOrderNumber}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        productName.isNotEmpty
                            ? productName
                            : AppLocalizations.of(context)!.unknown_product,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationName.isNotEmpty
                                  ? locationName
                                  : AppLocalizations.of(
                                      context,
                                    )!.location_not_selected,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (chiller.refillCount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context)!.refills}: ${chiller.refillCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (chiller.lastRefilledDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context)!.last_refilled}: '
                                '${chiller.lastRefilledDate!.toString().substring(0, 10)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            // A chiller with no assigned venue is still listed, but there is
            // nowhere to send a refill, so it is not offered one.
            if (chiller.canRefill)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final selectedCategoryItem = refillCategoryItem(
                      chiller.deliveredLocation,
                    );

                    final waterCartons = HomeTab.cachedProducts
                        .where(
                          (p) => p.serialNumber == 1 || p.serialNumber == 4,
                        )
                        .toList();

                    // The chiller's own sub-order id: it makes this a refill,
                    // so the backend links the order to this chiller and locks
                    // delivery to its location.
                    ChooseWaterPackageScreen.showAsBottomSheet(
                      context,
                      selectedCategories: [selectedCategoryItem],
                      availableProducts: waterCartons,
                      chillerRefillSubOrderId: chiller.id,
                      chillerRefillDestination: chiller.checkoutDestination,
                    );
                  },

                  child: Text(
                    AppLocalizations.of(context)!.order_water_to_this_chiller,
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
  }
}
