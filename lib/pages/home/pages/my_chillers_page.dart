import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/chiller_model.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'dart:developer';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/chiller_details_page.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/models/mosque.dart';

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
      } else {
        _errorMessage = e.toString();
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
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              HomeScreen.switchTabNotifier.value = 0;
            },
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
                              : _chillers.isEmpty
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
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _chillers.length,
                                  itemBuilder: (context, index) {
                                    final chiller = _chillers[index];
                                    if (chiller.isChillerAvailable) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _buildChillerItem(chiller),
                                      );
                                    }
                                    return const SizedBox.shrink();
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
                      Text(
                        '${AppLocalizations.of(context)!.order_number}: ${chiller.subOrderNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productName.isNotEmpty
                            ? productName
                            : 'Unknown Product',
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
                                  : 'Unknown Location',
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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
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
                  final category = HomeTab.cachedCategories.firstWhere(
                    (c) => c.slug == chiller.deliveredLocation?.type,
                    orElse: () => HomeTab.cachedCategories.firstWhere(
                      (c) => c.slug == 'mosques', // fallback
                      orElse: () => HomeTab.cachedCategories.first,
                    ),
                  );

                  final specificPlace = Mosque(
                    id: chiller.deliveredLocation?.id ?? '',
                    name: chiller.deliveredLocation?.name ?? '',
                    nameAr: chiller.deliveredLocation?.nameAr ?? '',
                    beneficiaryCount: 0,
                    latitude: chiller.deliveredLocation?.latitude ?? 0.0,
                    longitude: chiller.deliveredLocation?.longitude ?? 0.0,
                    address: chiller.deliveredLocation?.address ?? '',
                    image: '',
                    zone: null,
                    isActive: true,
                  );

                  final selectedCategoryItem = SelectedCategoryItem(
                    category: category,
                    optionType: 'specific',
                    specificData: specificPlace,
                  );

                  final waterCartons = HomeTab.cachedProducts
                      .where((p) => p.serialNumber == 1 || p.serialNumber == 4)
                      .toList();

                  ChooseWaterPackageScreen.showAsBottomSheet(
                    context,
                    selectedCategories: [selectedCategoryItem],
                    availableProducts: waterCartons,
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
