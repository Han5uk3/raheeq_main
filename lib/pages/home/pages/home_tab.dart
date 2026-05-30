import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/language_switch.dart';
import 'package:raheeq_main/models/banner_data.dart';
import 'package:raheeq_main/models/campaign.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import '../../../storage/auth_storage.dart';
import 'campaign_detail_page.dart';
import 'quick_service_page.dart';
import 'city_selector_page.dart';
import 'specific_mosque_page.dart';
import '../widgets/option_selector_dialog.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _pageController = PageController(initialPage: 1000);
  Timer? _timer;

  // Static cache to prevent reloading data every time tab is opened
  static bool _hasLoadedOnce = false;
  static List<BannerData> _cachedBannerData = [];
  static List<Campaign> _cachedCampaigns = [];
  static List<Category> _cachedCategories = [];
  static List<Product> _cachedProducts = [];

  bool _isLoading = true;
  String? _errorMessage;

  List<BannerData> _bannerData = [];
  List<Campaign> _campaigns = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  List<SelectedCategoryItem> _selectedItems = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_hasLoadedOnce) {
      _bannerData = _cachedBannerData;
      _campaigns = _cachedCampaigns;
      _categories = _cachedCategories;
      _products = _cachedProducts;
      _isLoading = false;
      if (_bannerData.isNotEmpty) {
        _currentIndex = 1000 % _bannerData.length;
      }
    } else {
      _fetchHomeData();
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _bannerData.length > 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutExpo,
        );
      }
    });
  }

  Future<void> _fetchHomeData() async {
    try {
      setState(() {
        if (!_hasLoadedOnce) _isLoading = true;
        _errorMessage = null;
      });

      // Fetch user profile in background to get latest name/wallet values
      try {
        await ApiService().getProfile();
      } catch (_) {}

      final response = await ApiService().getHome();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final banners = ((data['banners'] as List<dynamic>?) ?? [])
            .map((b) => BannerData.fromJson(b as Map<String, dynamic>))
            .toList();
        final campaigns =
            ((data['campaigns'] as List<dynamic>?) ?? [])
                .map((c) => Campaign.fromJson(c as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        final categories =
            ((data['categories'] as List<dynamic>?) ?? [])
                .map((c) => Category.fromJson(c as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final products = ((data['products'] as List<dynamic>?) ?? [])
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
        _cachedBannerData = banners;
        _cachedCampaigns = campaigns;
        _cachedCategories = categories;
        _cachedProducts = products;
        _hasLoadedOnce = true;

        if (mounted) {
          setState(() {
            _bannerData = banners;
            _campaigns = campaigns;
            _categories = categories;
            _products = products;
            _isLoading = false;
            _errorMessage = null;

            if (_bannerData.isNotEmpty) {
              _currentIndex = 1000 % _bannerData.length;
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              response.data['message'] ?? "Failed to load home page data";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred while connecting to the server";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return buildLoadingSkeleton(context);
    }

    if (_errorMessage != null && _bannerData.isEmpty) {
      return buildErrorWidget(context);
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      children: [
        Container(
          color: Colors
              .white, // Covers native window background under transparent gradient
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x4D91E3FE), Color(0xFF6EC4E0)],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _fetchHomeData,
              color: AppColors.buttonBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AuthStorage.user?.fullName ?? "Abdullah Hassan",
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isAr ? "السلام عليكم" : "Assalamu Alaikum",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const LanguageSwitchButton(),
                              const SizedBox(width: 12),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {},
                                    customBorder: const CircleBorder(),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppColors.buttonBlueDark,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Carousel Section
                    SizedBox(
                      height: 180,
                      child: _bannerData.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  color: AppColors.buttonBlueDark,
                                  child: const Center(
                                    child: Icon(
                                      Icons.water_drop,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index % _bannerData.length;
                                });
                              },
                              itemBuilder: (context, index) {
                                final actualIndex = index % _bannerData.length;
                                final banner = _bannerData[actualIndex];
                                final bannerUrl = banner.image;
                                final bannerName = banner.name;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CachedNetworkImage(
                                      imageUrl: bannerUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.buttonBlueDark,
                                        child: const Center(
                                          child: WaterLoadingIndicator(
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: AppColors.buttonBlueDark,
                                            child: Center(
                                              child: Text(
                                                bannerName,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Expanding Indicator
                    if (_bannerData.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_bannerData.length, (index) {
                          bool isActive = _currentIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 32 : 12,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.buttonBlueDark
                                  : AppColors.buttonBlueDark.withAlpha(100),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.buttonBlueDark
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),

                    const SizedBox(height: 24),

                    // Bottom Content Area (White Rounded)
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Campaigns Section (Dynamic Cards)
                          if (_campaigns.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: List.generate(_campaigns.length, (
                                  index,
                                ) {
                                  return buildCampaignCard(
                                    context,
                                    _campaigns[index],
                                    index,
                                  );
                                }),
                              ),
                            ),

                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildQuickServicesSection(context),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildRecentDonationCard(context),
                          ),
                          const SizedBox(height: 24),
                          buildFeaturedProductsSection(context),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildYourImpactSection(context),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildBottomText(context),
                          ),
                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedItems.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 130,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.buttonBlue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr
                        ? 'محدد: ${_selectedItems.length} عناصر'
                        : 'Selected: ${_selectedItems.length} items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to QuickServicePage with the first selected item, as a placeholder
                      if (_selectedItems.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChooseWaterPackageScreen(
                              selectedCategories: _selectedItems,
                              availableProducts: List<Product>.from(_products),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.buttonBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      isAr ? 'اطلب الآن' : 'Order Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget buildLoadingSkeleton(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x4D91E3FE), Color(0xFF6EC4E0)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (index) => Container(
                            height: 100,
                            width: (MediaQuery.of(context).size.width - 64) / 3,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 240),
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

  Widget buildErrorWidget(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      color: Colors.white,
      child: Center(
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
                isAr
                    ? "حدث خطأ أثناء تحميل البيانات"
                    : "Failed to load home page",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchHomeData,
                icon: const Icon(Icons.refresh),
                label: Text(isAr ? "إعادة المحاولة" : "Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCampaignCard(BuildContext context, Campaign campaign, int index) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = campaign.localizedTitle(isAr);
    final description = campaign.localizedDescription(isAr);
    final imageUrl = campaign.image;

    final bool isEven = index % 2 == 0;
    final primaryColor = isEven
        ? const Color(0xFF3CAAD4)
        : const Color(0xFF086091);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CampaignDetailPage(campaign: campaign),
          ),
        );
      },
      child: Container(
        height: isEven ? 200 : 150,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: primaryColor.withValues(alpha: 0.3)),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/masjid/masjid_al_haram.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Subscribe badge (top-right)
              // if (campaign.canSubscribe)
              //   Positioned(
              //     top: 12,
              //     right: 12,
              //     child: Container(
              //       padding: const EdgeInsets.symmetric(
              //         horizontal: 10,
              //         vertical: 5,
              //       ),
              //       decoration: BoxDecoration(
              //         color: Colors.white.withValues(alpha: 0.95),
              //         borderRadius: BorderRadius.circular(20),
              //       ),
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           const Icon(
              //             Icons.repeat_rounded,
              //             size: 12,
              //             color: AppColors.buttonBlueDark,
              //           ),
              //           const SizedBox(width: 4),
              //           Text(
              //             isAr ? 'اشتراك متاح' : 'Subscribe',
              //             style: const TextStyle(
              //               fontSize: 11,
              //               fontWeight: FontWeight.w700,
              //               color: AppColors.buttonBlueDark,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // Text content
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  top: isEven ? 40 : 25,
                  right: 20,
                  bottom: 20,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth * 0.58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: isEven ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: isEven ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: isEven ? 24 : 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Donate Now button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAr ? 'تبرع الآن   ' : 'Donate Now   ',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        size: 12,
                                        Icons.arrow_forward,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQuickServicesSection(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? "أعمال سريعة" : "Quick Actions",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          isAr
              ? "اختر قضيتك واصنع فرقاً"
              : "Choose your cause and make an impact",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final label = category.localizedLabel(isAr);
            final imageUrl = category.image.trim();
            final slug = category.slug;
            final existingIndex = _selectedItems.indexWhere(
              (item) => item.category.id == category.id,
            );
            final isSelected = existingIndex != -1;
            final requiresChoosing =
                slug == 'orphanages' ||
                slug == 'meqat_mosques' ||
                slug == 'mosques_in_need' ||
                slug == 'specific_mosque';

            return GestureDetector(
              onTap: () async {
                if (isSelected && !requiresChoosing) {
                  setState(() {
                    _selectedItems.removeAt(existingIndex);
                  });
                  return;
                }

                if (slug == 'orphanages' || slug == 'meqat_mosques') {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) => OptionSelectorDialog(
                      title: label,
                      showClearOption: isSelected,
                    ),
                  );
                  if (result != null) {
                    if (result == 'clear') {
                      setState(() {
                        _selectedItems.removeAt(existingIndex);
                      });
                      return;
                    }

                    if (result == 'most_in_need') {
                      setState(() {
                        _selectedItems.add(
                          SelectedCategoryItem(
                            category: category,
                            optionType: 'most_in_need',
                          ),
                        );
                      });
                    } else if (result == 'specific') {
                      final specificItem = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SpecificMosquePage(slug: category.slug),
                        ),
                      );
                      if (specificItem != null) {
                        setState(() {
                          _selectedItems.add(
                            SelectedCategoryItem(
                              category: category,
                              optionType: 'specific',
                              specificData: specificItem,
                            ),
                          );
                        });
                      }
                    }
                  }
                  return;
                }

                if (slug == 'mosques_in_need') {
                  final city = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CitySelectorPage()),
                  );
                  if (city != null) {
                    setState(() {
                      _selectedItems.add(
                        SelectedCategoryItem(
                          category: category,
                          optionType: 'most_in_need',
                          specificData: city,
                        ),
                      );
                    });
                  }
                  return;
                }

                if (slug == 'specific_mosque') {
                  final mosque = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpecificMosquePage(slug: category.slug),
                    ),
                  );
                  if (mosque != null) {
                    setState(() {
                      _selectedItems.add(
                        SelectedCategoryItem(
                          category: category,
                          optionType: 'specific',
                          specificData: mosque,
                        ),
                      );
                    });
                  }
                  return;
                }

                setState(() {
                  _selectedItems.add(
                    SelectedCategoryItem(
                      category: category,
                      optionType: 'none',
                    ),
                  );
                });
              },
              child: buildGridCard(
                context,
                label,
                imageUrl,
                isSelected: existingIndex != -1,
                requiresChoosing:
                    slug == 'orphanages' ||
                    slug == 'meqat_mosques' ||
                    slug == 'mosques_in_need' ||
                    slug == 'specific_mosque',
                onClear: existingIndex != -1
                    ? () {
                        setState(() {
                          _selectedItems.removeAt(existingIndex);
                        });
                      }
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildFeaturedProductsSection(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isAr ? "منتجات متميزة" : "Featured Products",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final name = product.localizedName(isAr);
              final subtitle = product.localizedSubtitle(isAr);
              final imageUrl = product.image;
              final price = product.price;

              return Container(
                width: 200,
                margin: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == _products.length - 1 ? 16 : 8,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xffE2E2E2), width: 1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 12,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            color: const Color(0xFFF8FAFB),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: WaterLoadingIndicator(size: 30),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.water_drop,
                                size: 40,
                                color: AppColors.buttonBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$price SAR",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildRecentDonationCard(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6A8F), Color(0xFF91E3FE)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recent Donations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "View status and delivery details.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward,
              size: 14,
              color: AppColors.buttonBlueDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPill(IconData icon, String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1D39),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
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

  Widget buildGridCard(
    BuildContext context,
    String title,
    String imgPath, {
    bool isSelected = false,
    bool requiresChoosing = false,
    VoidCallback? onClear,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF6F6F6),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.buttonBlueDark, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFDDEEF7),
                      child: imgPath.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.water_drop_outlined,
                                color: AppColors.buttonBlueDark,
                                size: 32,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: imgPath,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: WaterLoadingIndicator(size: 30),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.water_drop_outlined,
                                      color: AppColors.buttonBlueDark,
                                      size: 32,
                                    ),
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        if (onClear != null)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildNearbyMosqueSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Nearby Mosque",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 336,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return buildNearbyMosqueCard(
                context,
                "Sheikh Zayed Mosque",
                "Abu Dhabi, UAE",
                "https://upload.wikimedia.org/wikipedia/en/thumb/7/7d/Sheikh_Zayed_Mosque_view.jpg/500px-Sheikh_Zayed_Mosque_view.jpg",
                index,
                5,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildNearbyMosqueCard(
    BuildContext context,
    String title,
    String location,
    String imgPath,
    int index,
    int totalLength,
  ) {
    return Container(
      width: 260,
      margin: EdgeInsets.only(
        left: index == 0 ? 16 : 8,
        right: index == totalLength - 1 ? 16 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffE2E2E2), width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 16,
              right: 16,
              bottom: 8,
            ),
            child: buildHighNeedBadge(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.black,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const Text(
                  ", 2.5 km",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imgPath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black.withValues(alpha: 0.05),
                    child: const Center(child: WaterLoadingIndicator(size: 30)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Donate Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHighNeedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.buttonBlueLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: AppColors.buttonBlue, size: 12),
          Text(
            " High Need",
            style: TextStyle(fontSize: 12, color: AppColors.buttonBlue),
          ),
        ],
      ),
    );
  }

  Widget buildYourImpactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Impact",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                _buildImpactPill(Icons.people, "50", "People Helped"),
                const SizedBox(width: 12),
                _buildImpactPill(Icons.water_drop, "85L", "Water Donated"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildImpactPill(Icons.mosque, "10", "Mosques Served"),
                const SizedBox(width: 12),
                _buildImpactPill(Icons.inventory_2, "12", "Water Cartons"),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget buildBottomText(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Give Water.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.grey,
          ),
        ),
        Text(
          "Deliver Blessings.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
