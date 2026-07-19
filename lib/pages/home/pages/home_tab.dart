import 'package:dio/dio.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/services/network_monitor.dart';
import 'package:raheeq_main/services/snackbar_insets_services.dart';
import 'dart:developer';
import 'package:raheeq_main/utils/formatters.dart';

import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/models/banner_data.dart';
import 'package:raheeq_main/models/campaign.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/city.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/impact.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import '../../../storage/auth_storage.dart';
import 'campaign_detail_page.dart';
import '../widgets/city_selector_dialog.dart';
import 'specific_mosque_page.dart';
import '../widgets/option_selector_dialog.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/choose_water_package_screen.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/pages/home/pages/impact_page.dart';
import 'package:raheeq_main/pages/home/pages/notifications_page.dart';
import 'package:raheeq_main/main.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  /// Queue a mosque selection to be picked up when the Home tab becomes active.
  static void scheduleMosqueItem(SelectedCategoryItem item) {
    _HomeTabState._pendingItems.add(item);
  }

  /// Exposes the cached categories list to external pages.
  static List<Category> get cachedCategories => _HomeTabState._cachedCategories;

  /// Clears the basket. Called after a successful payment.
  static void clearBasket() => _HomeTabState._clearBasket();

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with RouteAware, WidgetsBindingObserver {
  final PageController _pageController = PageController(
    initialPage: 1000,
    viewportFraction: 0.9,
  );
  Timer? _timer;

  // Static cache to prevent reloading data every time tab is opened
  static bool _hasLoadedOnce = false;
  static List<BannerData> _cachedBannerData = [];
  static List<Campaign> _cachedCampaigns = [];
  static List<Category> _cachedCategories = [];
  static List<Product> _cachedProducts = [];
  static List<Product> _cachedEssentialProducts = [];
  static List<City> _cachedCities = [];
  static ImpactModel? _cachedImpactData;
  static String? _cachedHomeDataJson;
  static String? _cachedHomeETag;
  static String? _cachedProfileETag;
  static String? _cachedCitiesETag;
  static String? _cachedImpactETag;
  static String? _cachedNotificationsETag;
  static int _cachedUnreadCount = 0;

  // Queue for items added from external pages (e.g., Saved Mosques)
  static final List<SelectedCategoryItem> _pendingItems = [];

  static final Category _essentialCategory = Category(
    id: 'essential_supplies',
    slug: 'essential_supplies',
    labelEn: 'Essential Supplies',
    labelAr: 'مستلزمات أساسية',
    image: '',
    sortOrder: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;

  List<BannerData> _bannerData = [];
  List<Campaign> _campaigns = [];
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _essentialProducts = [];
  List<City> _citiesList = [];
  ImpactModel? _impactData;
  static List<SelectedCategoryItem> _selectedItems = [];

  /// Clears the basket. Called after a successful payment.
  static void _clearBasket() {
    _selectedItems.clear();
  }

  int _currentIndex = 0;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    SnackbarInsets.setBottomInset(kBottomNavigationBarHeight + 10);
    WidgetsBinding.instance.addObserver(this);
    _unreadNotificationsCount = _cachedUnreadCount;
    if (_hasLoadedOnce) {
      _bannerData = _cachedBannerData;
      _campaigns = _cachedCampaigns;
      _categories = _cachedCategories;
      _products = _cachedProducts;
      _essentialProducts = _cachedEssentialProducts;
      _citiesList = _cachedCities;
      _impactData = _cachedImpactData;
      _isLoading = false;
      if (_bannerData.isNotEmpty) {
        _currentIndex = 1000 % _bannerData.length;
      }
    }
    _fetchHomeData();
    _startTimer();
    _drainPendingItems();
  }

  void _drainPendingItems() {
    if (_pendingItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            for (var pending in _pendingItems) {
              if (pending.optionType == 'specific' &&
                  pending.specificData is Place) {
                final pendingPlace = pending.specificData as Place;
                bool exists = _selectedItems.any((item) {
                  return item.optionType == 'specific' &&
                      item.specificData is Place &&
                      (item.specificData as Place).id == pendingPlace.id;
                });
                if (!exists) {
                  _selectedItems.add(pending);
                }
              } else {
                _selectedItems.add(pending);
              }
            }
            _pendingItems.clear();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _drainPendingItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    _fetchHomeData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchHomeData();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    SnackbarInsets.clear();
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

      // Run independent API calls concurrently to reduce load time
      final profileFuture = () async {
        try {
          final profileResponse = await ApiService().getProfile(
            etag: _cachedProfileETag,
          );
          if (profileResponse.statusCode == 304) {
            log(
              'Profile data unchanged (304). Using cached ETag.',
              name: 'HomeTab',
            );
          } else if (profileResponse.statusCode == 200) {
            final newEtag = profileResponse.headers.value('etag');
            if (newEtag != null) _cachedProfileETag = newEtag;
          }
        } catch (_) {}
      }();

      final citiesFuture = () async {
        try {
          final citiesResponse = await ApiService().getCities(
            showSnackbar: true,
            etag: _cachedCitiesETag,
          );
          if (citiesResponse.statusCode == 304) {
            log(
              'Cities data unchanged (304). Using cached ETag.',
              name: 'HomeTab',
            );
            return;
          }
          if (citiesResponse.statusCode == 200 &&
              citiesResponse.data['success'] == true) {
            final newEtag = citiesResponse.headers.value('etag');
            if (newEtag != null) _cachedCitiesETag = newEtag;

            final List<dynamic> data = citiesResponse.data['data'] ?? [];
            _cachedCities = data
                .map((e) => City.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          log('Error fetching cities: $e', name: 'HomeTab');
        }
      }();

      final impactFuture = () async {
        try {
          final impactRes = await ApiService().getImpact(
            showSnackbar: true,
            etag: _cachedImpactETag,
          );
          if (impactRes.statusCode == 304) {
            log(
              'Impact data unchanged (304). Using cached ETag.',
              name: 'HomeTab',
            );
            return;
          }
          if (impactRes.statusCode == 200 &&
              impactRes.data['success'] == true) {
            final newEtag = impactRes.headers.value('etag');
            if (newEtag != null) _cachedImpactETag = newEtag;

            _cachedImpactData = ImpactModel.fromJson(impactRes.data['data']);
          }
        } catch (e) {
          log('Error fetching impact: $e', name: 'HomeTab');
        }
      }();

      final notificationsFuture = () async {
        try {
          final unreadRes = await ApiService().getUnreadNotificationsCount(
            showSnackbar: true,
            etag: _cachedNotificationsETag,
          );
          if (unreadRes.statusCode == 304) {
            log('Unread notifications unchanged (304).', name: 'HomeTab');
            if (mounted) {
              setState(() {
                _unreadNotificationsCount = _cachedUnreadCount;
              });
            }
            return;
          }
          if (unreadRes.statusCode == 200 &&
              unreadRes.data['success'] == true) {
            final newEtag = unreadRes.headers.value('etag');
            if (newEtag != null) _cachedNotificationsETag = newEtag;

            final countData = unreadRes.data['data'];
            if (countData != null && countData['count'] != null) {
              _cachedUnreadCount = countData['count'] as int;
              _unreadNotificationsCount = _cachedUnreadCount;
            } else if (countData is int) {
              _cachedUnreadCount = countData;
              _unreadNotificationsCount = _cachedUnreadCount;
            }
          }
        } catch (e) {
          log('Error fetching unread notifications count: $e', name: 'HomeTab');
        }
      }();

      final homeFuture = ApiService().getHome(etag: _cachedHomeETag);

      await Future.wait([
        profileFuture,
        citiesFuture,
        impactFuture,
        notificationsFuture,
        homeFuture,
      ]);

      final response = await homeFuture;

      if (response.statusCode == 304) {
        log(
          'API returned 304 Not Modified. Using cached ETag data.',
          name: 'HomeTab',
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newEtag = response.headers.value('etag');
        if (newEtag != null) {
          _cachedHomeETag = newEtag;
        }

        final rawData = response.data['data'];
        final currentJson = jsonEncode(rawData);

        if (_hasLoadedOnce && currentJson == _cachedHomeDataJson) {
          log('Home data unchanged. Skipping rebuild.', name: 'HomeTab');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        _cachedHomeDataJson = currentJson;
        final data = rawData as Map<String, dynamic>;

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
        final essentialProducts =
            ((data['essentialProducts'] as List<dynamic>?) ?? [])
                .map((p) => Product.fromJson(p as Map<String, dynamic>))
                .toList();

        if (mounted) {
          final futures = <Future<void>>[];
          for (final b in banners) {
            if (b.image.isNotEmpty) {
              futures.add(
                precacheImage(
                  CachedNetworkImageProvider(b.image),
                  context,
                ).catchError((_) {}),
              );
            }
          }
          for (final c in campaigns) {
            if (c.image.isNotEmpty) {
              futures.add(
                precacheImage(
                  CachedNetworkImageProvider(c.image),
                  context,
                ).catchError((_) {}),
              );
            }
          }
          for (final cat in categories) {
            if (cat.image.isNotEmpty) {
              futures.add(
                precacheImage(
                  CachedNetworkImageProvider(cat.image.trim()),
                  context,
                ).catchError((_) {}),
              );
            }
          }
          for (final p in essentialProducts) {
            if (p.image.isNotEmpty) {
              futures.add(
                precacheImage(
                  CachedNetworkImageProvider(p.image),
                  context,
                ).catchError((_) {}),
              );
            }
          }

          if (futures.isNotEmpty) {
            await Future.wait(
              futures,
            ).timeout(const Duration(seconds: 2), onTimeout: () => []);
          }
        }

        _cachedBannerData = banners;
        _cachedCampaigns = campaigns;
        _cachedCategories = categories;
        _cachedProducts = products;
        _cachedEssentialProducts = essentialProducts;
        _hasLoadedOnce = true;

        if (mounted) {
          setState(() {
            _bannerData = banners;
            _campaigns = campaigns;
            _categories = categories;
            _products = products;
            _essentialProducts = essentialProducts;
            _citiesList = _cachedCities;
            _impactData = _cachedImpactData;
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
        if (e.toString().contains("connection error")) {
          _errorMessage = AppLocalizations.of(context)!.internet_error;
        } else if (e is DioException) {
          _errorMessage =
              e.response?.data['message'] ??
              AppLocalizations.of(context)!.failed_to_load_home_page;
        } else {
          _errorMessage = AppLocalizations.of(context)!.error;
        }
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

    return Stack(
      children: [
        Container(
          color: Colors
              .white, // Covers native window background under transparent gradient
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.buttonBlueDark,
                  Color.fromARGB(255, 25, 141, 195),
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _fetchHomeData,
              color: AppColors.buttonBlueDark,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        60,
                        16,
                        8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${AppLocalizations.of(context)!.welcome}, ${AuthStorage.user?.fullName ?? "User"}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsPage(),
                                ),
                              );
                              // Refresh notifications count when returning
                              _fetchHomeData();
                            },
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 36,
                                width: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.buttonBlueDark,
                                      size: 20,
                                    ),
                                    if (_unreadNotificationsCount > 0)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '$_unreadNotificationsCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
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

                    // Carousel Section
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // The PageView viewportFraction is 0.9
                        final pageItemWidth = constraints.maxWidth * 0.9;
                        // The banner item has symmetric horizontal padding of 8 (16 total)
                        final bannerWidth = pageItemWidth - 16;
                        // The banner's original dimensions are 790x418
                        final bannerHeight = bannerWidth * (418 / 790);

                        return SizedBox(
                          height: bannerHeight,
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
                                  physics: _bannerData.length > 1
                                      ? null
                                      : const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentIndex =
                                          index % _bannerData.length;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final actualIndex =
                                        index % _bannerData.length;
                                    final banner = _bannerData[actualIndex];
                                    final bannerUrl = banner.image;
                                    final bannerName = banner.name;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: CachedNetworkImage(
                                          imageUrl: bannerUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                                child: Container(
                                                  color: Colors.white,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        );
                      },
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
                                  ? AppColors.white
                                  : Colors.white24,
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
                          // Campaigns Section (Dynamic Cards)
                          if (_campaigns.any((c) => c.products.isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: _campaigns
                                    .where((c) => c.products.isNotEmpty)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      if ((entry.value.description == " " ||
                                              entry
                                                  .value
                                                  .description
                                                  .isEmpty) &&
                                          (entry.value.descriptionAr == " " ||
                                              entry
                                                  .value
                                                  .descriptionAr
                                                  .isEmpty)) {
                                        return buildCampaignCard(
                                          context,
                                          entry.value,
                                          entry.key,
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          child: buildOldCampaignCard(
                                            context,
                                            entry.value,
                                            entry.key,
                                          ),
                                        );
                                      }
                                    })
                                    .toList(),
                              ),
                            ),

                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildQuickServicesSection(context),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildRecentDonationCard(context),
                          ),

                          buildEssentialMosqueSuppliesSection(context),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: buildYourImpactSection(context),
                          ),

                          const SizedBox(height: 120),
                          if (_selectedItems.isNotEmpty) ...{
                            SizedBox(height: 80),
                          },
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
            bottom: 115,
            child: Listener(
              onPointerDown: (_) {
                debugPrint("Pointer reached pill");
              },
              child: BottomActionPill(
                titleWidget: Text(
                  AppLocalizations.of(
                    context,
                  )!.selected_items_count(_selectedItems.length),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                buttonText: AppLocalizations.of(context)!.order_now,

                onButtonTap:
                    (NetworkMonitor.instance.status.value !=
                        NetworkStatus.online)
                    ? () {
                        CustomSnackbar.show(
                          context: context,
                          message: AppLocalizations.of(context)!.internet_error,
                          isError: true,
                        );
                        return;
                      }
                    : () async {
                        final isEssential = _selectedItems.any(
                          (i) => i.category.slug == 'essential_supplies',
                        );
                        if (isEssential) {
                          final orderStates = <OrderCategoryState>[];
                          for (final item in _selectedItems) {
                            if (item.specificData is EssentialSelection) {
                              final selection =
                                  item.specificData as EssentialSelection;
                              orderStates.add(
                                OrderCategoryState(
                                  categoryItem: SelectedCategoryItem(
                                    category: item.category,
                                    optionType: item.optionType,
                                    specificData: selection.place,
                                  ),
                                  selectedProducts: [
                                    SelectedProduct(
                                      product: selection.product,
                                      quantity: selection.product.minQuantity,
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                          if (orderStates.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReviewOrderPage(orderStates: orderStates),
                              ),
                            );
                          }
                        } else {
                          if (_selectedItems.isNotEmpty) {
                            ChooseWaterPackageScreen.showAsBottomSheet(
                              context,
                              selectedCategories: _selectedItems,
                              availableProducts: List<Product>.from(_products),
                            );
                          }
                        }
                      },
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
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [AppColors.buttonBlueDark, Color(0xFF6EC4E0)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 60, 16, 20),
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
                            color: const Color.fromARGB(
                              255,
                              180,
                              170,
                              170,
                            ).withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 210,
                        width: double.infinity,
                        margin: const EdgeInsetsDirectional.only(bottom: 0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 150,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 16,
                                        top: 85,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            height: 44,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            height: 32,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 16,
                                        top: 16,
                                        bottom: 16,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 210,
                        width: double.infinity,
                        margin: const EdgeInsetsDirectional.only(bottom: 0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 150,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 16,
                                        top: 85,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            height: 44,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            height: 32,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 16,
                                        top: 16,
                                        bottom: 16,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                AppLocalizations.of(context)!.failed_to_load_home_page,
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
      ),
    );
  }

  Future<bool> _showClearBasketDialog(
    BuildContext context,
    String targetName,
    bool isAr,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.warning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!
                    .your_current_basket_will_be_cleared_and_you_will_be_moved_to_targetname
                    .replaceAll('\$targetName', targetName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.i_understand,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  Widget buildCampaignCard(BuildContext context, Campaign campaign, int index) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = campaign.localizedTitle(isAr);

    final imageUrl = campaign.image;

    return GestureDetector(
      onTap: () async {
        if (_selectedItems.isNotEmpty) {
          final shouldProceed = await _showClearBasketDialog(
            context,
            title,
            isAr,
          );
          if (shouldProceed) {
            setState(() {
              _selectedItems.clear();
            });
            if (context.mounted) {
              if (NetworkMonitor.instance.status.value ==
                  NetworkStatus.offline) {
                CustomSnackbar.show(
                  context: context,
                  message: AppLocalizations.of(context)!.internet_error,
                  isError: true,
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CampaignDetailPage(campaign: campaign),
                ),
              );
            }
          }
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CampaignDetailPage(campaign: campaign),
            ),
          );
        }
      },
      child: FittedBox(
        fit: BoxFit.fitWidth,
        clipBehavior: Clip.none,
        child: Container(
          height: 210,
          width: 420, // Fixed width for design baseline
          margin: const EdgeInsetsDirectional.only(bottom: 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dark blue background container — half the total height, aligned to bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.buttonBlueDark,
                        Color.fromARGB(255, 31, 163, 224),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage("assets/others/Groupbg.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 40,

                height: 150,
                child: SizedBox(
                  height: 160,
                  width: 160,
                  child: Image.asset("assets/others/Group.png"),
                ),
              ),

              Positioned(
                right: -50,
                top: 40,
                height: 200,
                width: 200,
                child: SizedBox(child: Image.asset("assets/others/Group.png")),
              ),
              // Content row on top
              Positioned.fill(
                child: Row(
                  children: [
                    // Left side: Title + Button
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          top: 65,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.donate_now,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A385F),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A385F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      forwardArrowIcon(context),
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Right side: Image extends full height
                    Expanded(
                      flex: 9,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 16,
                          top: 16,
                          bottom: 16,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOldCampaignCard(
    BuildContext context,
    Campaign campaign,
    int index,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = campaign.localizedTitle(isAr);
    final description = campaign.localizedDescription(isAr);

    final imageUrl = campaign.image;
    final bannerWidth = MediaQuery.of(context).size.width - 32;
    const minBannerHeight = 195.0;

    return GestureDetector(
      onTap: () async {
        if (NetworkMonitor.instance.status.value == NetworkStatus.offline) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.internet_error,
            isError: true,
          );
          return;
        }
        if (_selectedItems.isNotEmpty) {
          final shouldProceed = await _showClearBasketDialog(
            context,
            title,
            isAr,
          );
          if (shouldProceed) {
            setState(() {
              _selectedItems.clear();
            });
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CampaignDetailPage(campaign: campaign),
                ),
              );
            }
          }
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CampaignDetailPage(campaign: campaign),
            ),
          );
        }
      },
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Container(
          width: bannerWidth,
          constraints: const BoxConstraints(minHeight: minBannerHeight),
          margin: const EdgeInsetsDirectional.only(bottom: 0),
          child: IntrinsicHeight(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Dark blue background container — fills to match content height
                Positioned.fill(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          matchTextDirection: true,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[500]!,
                            child: Container(color: Colors.grey[200]),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin:
                                Directionality.of(context) == TextDirection.rtl
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            end: Directionality.of(context) == TextDirection.rtl
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            stops: [0.25, 1.0],
                            colors: [
                              AppColors.buttonBlueDark.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content row — non-positioned, so it drives the Stack's height
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          top: 16,
                          bottom: 16,
                          end: 16,
                        ),
                        child: Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              spacing: 8,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 8,
                                      child: Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    Expanded(flex: 8, child: SizedBox()),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: SizedBox()),
                                  ],
                                ),
                              ],
                            ),
                            Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.donate_now,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.buttonBlueDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.buttonBlueDark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        forwardArrowIcon(context),
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          AppLocalizations.of(context)!.giving_opportunities,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          AppLocalizations.of(
            context,
          )!.choose_where_to_give_and_create_a_lasting_impact,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
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
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            String label = category.localizedLabel(isAr);

            String imageUrl = category.image.trim();
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
                if (_selectedItems.isNotEmpty &&
                    _selectedItems.any(
                      (item) => item.category.slug == 'essential_supplies',
                    )) {
                  final shouldProceed = await _showClearBasketDialog(
                    context,
                    label,
                    isAr,
                  );
                  if (shouldProceed) {
                    setState(() {
                      _selectedItems.clear();
                    });
                  } else {
                    return;
                  }
                }

                if (isSelected && !requiresChoosing) {
                  setState(() {
                    _selectedItems.removeAt(existingIndex);
                  });
                  return;
                }

                if (slug == 'orphanages' || slug == 'meqat_mosques') {
                  String? initialOption;
                  if (isSelected) {
                    initialOption = _selectedItems[existingIndex].optionType;
                  }

                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) => OptionSelectorDialog(
                      title: label,
                      showClearOption: isSelected,
                      initialOption: initialOption,
                    ),
                  );
                  if (result != null) {
                    if (result == 'clear') {
                      setState(() {
                        _selectedItems.removeWhere(
                          (item) => item.category.slug == slug,
                        );
                      });
                      return;
                    }

                    if (result == 'most_in_need') {
                      setState(() {
                        _selectedItems.removeWhere(
                          (item) => item.category.slug == slug,
                        );
                        _selectedItems.add(
                          SelectedCategoryItem(
                            category: category,
                            optionType: 'most_in_need',
                          ),
                        );
                      });
                    } else if (result == 'specific') {
                      final currentlySelected = _selectedItems
                          .where(
                            (item) =>
                                item.category.slug == slug &&
                                item.specificData is Place,
                          )
                          .map((item) => item.specificData as Place)
                          .toList();

                      final specificItems = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpecificMosquePage(
                            slug: category.slug,
                            initialSelections: currentlySelected,
                            title: label,
                          ),
                        ),
                      );
                      if (specificItems != null &&
                          specificItems is List<Place>) {
                        setState(() {
                          _selectedItems.removeWhere(
                            (item) => item.category.slug == slug,
                          );
                          for (final specificItem in specificItems) {
                            bool exists = _selectedItems.any((item) {
                              return item.optionType == 'specific' &&
                                  item.specificData is Place &&
                                  (item.specificData as Place).id ==
                                      specificItem.id;
                            });
                            if (!exists) {
                              _selectedItems.add(
                                SelectedCategoryItem(
                                  category: category,
                                  optionType: 'specific',
                                  specificData: specificItem,
                                ),
                              );
                            }
                          }
                        });
                      }
                    }
                  }
                  return;
                }

                if (slug == 'mosques_in_need') {
                  final currentlySelected = _selectedItems
                      .where(
                        (item) =>
                            item.category.slug == slug &&
                            item.specificData is City,
                      )
                      .map((item) => item.specificData as City)
                      .toList();

                  final cities = await showDialog<List<City>>(
                    context: context,
                    builder: (_) => CitySelectorDialog(
                      initialSelections: currentlySelected,
                      allCities: _citiesList,
                    ),
                  );

                  if (cities != null) {
                    setState(() {
                      _selectedItems.removeWhere(
                        (item) => item.category.slug == slug,
                      );
                      for (final city in cities) {
                        bool exists = _selectedItems.any((item) {
                          return item.optionType == 'most_in_need' &&
                              item.specificData is City &&
                              (item.specificData as City).id == city.id;
                        });
                        if (!exists) {
                          _selectedItems.add(
                            SelectedCategoryItem(
                              category: category,
                              optionType: 'most_in_need',
                              specificData: city,
                            ),
                          );
                        }
                      }
                    });
                  }
                  return;
                }

                if (slug == 'specific_mosque') {
                  final currentlySelected = _selectedItems
                      .where(
                        (item) =>
                            item.category.slug == slug &&
                            item.specificData is Place,
                      )
                      .map((item) => item.specificData as Place)
                      .toList();

                  final mosques = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpecificMosquePage(
                        slug: category.slug,
                        initialSelections: currentlySelected,
                        title: label,
                      ),
                    ),
                  );
                  if (mosques != null && mosques is List<Place>) {
                    setState(() {
                      _selectedItems.removeWhere(
                        (item) => item.category.slug == slug,
                      );
                      for (final mosque in mosques) {
                        bool exists = _selectedItems.any((item) {
                          return item.optionType == 'specific' &&
                              item.specificData is Place &&
                              (item.specificData as Place).id == mosque.id;
                        });
                        if (!exists) {
                          _selectedItems.add(
                            SelectedCategoryItem(
                              category: category,
                              optionType: 'specific',
                              specificData: mosque,
                            ),
                          );
                        }
                      }
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
                          _selectedItems.removeWhere(
                            (item) => item.category.slug == slug,
                          );
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

  Widget buildEssentialMosqueSuppliesSection(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_essentialProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.essential_mosque_supplies,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 215,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: _essentialProducts.length,
            itemBuilder: (context, index) {
              final product = _essentialProducts[index];
              final name = product.localizedName(isAr);

              final subtitle = product.localizedSubtitle(isAr);

              final price = product.price;

              final existingIndex = _selectedItems.indexWhere(
                (item) =>
                    item.category.slug == 'essential_supplies' &&
                    item.specificData is EssentialSelection &&
                    (item.specificData as EssentialSelection).product.id ==
                        product.id,
              );
              final isSelected = existingIndex != -1;

              return GestureDetector(
                onTap: () async {
                  if (isSelected) {
                    setState(() {
                      _selectedItems.removeWhere(
                        (item) =>
                            item.category.slug == 'essential_supplies' &&
                            item.specificData is EssentialSelection &&
                            (item.specificData as EssentialSelection)
                                    .product
                                    .id ==
                                product.id,
                      );
                    });
                    return;
                  }

                  if (_selectedItems.isNotEmpty &&
                      _selectedItems.any(
                        (item) => item.category.slug != 'essential_supplies',
                      )) {
                    final shouldProceed = await _showClearBasketDialog(
                      context,
                      name,
                      isAr,
                    );
                    if (!shouldProceed) {
                      return;
                    }
                    setState(() {
                      _selectedItems.clear();
                    });
                  }

                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) => OptionSelectorDialog(
                      title: AppLocalizations.of(context)!.mosques,
                      showClearOption: false,
                    ),
                  );

                  if (result == 'most_in_need') {
                    setState(() {
                      _selectedItems.add(
                        SelectedCategoryItem(
                          category: _essentialCategory,
                          optionType: 'most_in_need',
                          specificData: EssentialSelection(product: product),
                        ),
                      );
                    });
                  } else if (result == 'specific') {
                    final specificItems = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SpecificMosquePage(
                          slug: 'mosques_in_need',
                          initialSelections: const [],
                          title: name,
                        ),
                      ),
                    );
                    if (specificItems != null &&
                        specificItems is List<Place> &&
                        specificItems.isNotEmpty) {
                      setState(() {
                        for (final specificItem in specificItems) {
                          _selectedItems.add(
                            SelectedCategoryItem(
                              category: _essentialCategory,
                              optionType: 'specific',
                              specificData: EssentialSelection(
                                product: product,
                                place: specificItem,
                              ),
                            ),
                          );
                        }
                      });
                    }
                  }
                },
                child: _buildEssentialMosqueItem(
                  name,
                  index,
                  isSelected,
                  product,
                  subtitle,
                  () {
                    if (isSelected) {
                      setState(() {
                        _selectedItems.removeWhere(
                          (item) =>
                              item.category.slug == 'essential_supplies' &&
                              item.specificData is EssentialSelection &&
                              (item.specificData as EssentialSelection)
                                      .product
                                      .id ==
                                  product.id,
                        );
                      });
                      return;
                    }
                  },
                  price,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEssentialMosqueItem(
    String name,
    int index,
    bool isSelected,
    Product product,
    String subtitle,
    VoidCallback? onClear,
    double price,
  ) {
    return Container(
      width: 125,
      margin: EdgeInsetsDirectional.only(
        start: index == 0 ? 16 : 8,
        end: index == _essentialProducts.length - 1 ? 16 : 8,
        bottom: 12,
        top: 4,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            margin: EdgeInsets.all(0),
            color: Colors.white,
            elevation: isSelected ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? AppColors.buttonBlueDark
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    child: product.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.water_drop,
                                color: AppColors.buttonBlueDark,
                                size: 40,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.water_drop,
                              color: AppColors.buttonBlueDark,
                              size: 40,
                            ),
                          ),
                  ),
                ),

                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle row
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Product name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const Spacer(),
                        Text(
                          AppLocalizations.of(context)!.starting_from,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        // Price
                        Text(
                          '\u202A${AppLocalizations.of(context)!.sar_currency} ${price.toStringAsFixed(0)}\u202C',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            PositionedDirectional(
              top: -3,
              end: -8,
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
      ),
    );
  }

  Widget buildRecentDonationCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ImpactPage()),
        );
      },
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.buttonBlueDark,
                Color.fromARGB(255, 31, 163, 224),
              ],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
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
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.donations_overview,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.see_the_difference,
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
                child: Icon(
                  forwardArrowIcon(context),
                  size: 14,
                  color: AppColors.buttonBlueDark,
                ),
              ),
            ],
          ),
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
        Material(
          color: Colors.white,
          elevation: isSelected ? 3 : 1,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                    aspectRatio: 1.1,
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
                            : imgPath.startsWith('assets/')
                            ? Image.asset(imgPath, fit: BoxFit.contain)
                            : CachedNetworkImage(
                                imageUrl: imgPath,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white),
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
        ),
        if (onClear != null)
          PositionedDirectional(
            top: -8,
            end: -8,
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

  Widget buildYourImpactSection(BuildContext context) {
    if (_impactData == null) {
      return const SizedBox.shrink();
    }

    int totalCartons = 0;
    int totalChillers = 0;

    for (final breakup in _impactData!.productsBreakup) {
      final product = _products
          .where((p) => p.id == breakup.productId)
          .firstOrNull;
      if (product != null) {
        if (product.serialNumber == 1 || product.serialNumber == 4) {
          totalCartons += breakup.totalQuantity;
        } else if (product.serialNumber == 2) {
          totalChillers += breakup.totalQuantity;
        }
      } else {
        final nameLower = breakup.name.toLowerCase();
        final nameAr = breakup.nameAr;
        if (nameLower.contains('carton') || nameAr.contains('كرتون')) {
          totalCartons += breakup.totalQuantity;
        } else if (nameLower.contains('chiller') || nameAr.contains('برادة')) {
          totalChillers += breakup.totalQuantity;
        }
      }
    }

    final impactItems = [
      {
        'title': AppLocalizations.of(context)!.total_orders,
        'count': Formatters.formatCount(_impactData!.totalOrders),
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'title': AppLocalizations.of(context)!.people_helped,
        'count': Formatters.formatCount(totalCartons * 20),
        'icon': Icons.people_outline,
      },
      {
        'title': AppLocalizations.of(context)!.water_cartons,
        'count': Formatters.formatCount(totalCartons),
        'icon': Icons.water_drop_outlined,
      },
      {
        'title': AppLocalizations.of(context)!.chillers,
        'count': Formatters.formatCount(totalChillers),
        'icon': Icons.kitchen_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.your_impact,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 76,
          ),
          itemCount: impactItems.length,
          itemBuilder: (context, index) {
            final item = impactItems[index];
            return Material(
              elevation: 1,
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.buttonBlueDark,
                      Color.fromARGB(255, 31, 163, 224),
                    ],
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${item['count']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildBottomText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.give_water,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.grey,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.deliver_blessings,
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
