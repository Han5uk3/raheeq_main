import 'dart:async';
import 'dart:math' as math;

import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/pages/home/widgets/mosque_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import '../../../models/city.dart';
import '../../../models/mosque.dart';
import '../../../models/meqat_mosque.dart';
import '../../../models/orphanage.dart';
import '../../../models/place.dart';
import '../../../utils/colors.dart';
import '../../../utils/map_marker_icon.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

const double _selectedTileHeight = 56;
const double _selectedTileGap = 8;
const int _maxVisibleSelectedTiles = 4;
// Material's scrollbar thickness (8) plus its cross axis margin (2), rounded up.
const double _scrollbarGutter = 12;
const int _mapItemsLimit = 60;
// The mosque list loads this many at a time, and the next page once it is
// scrolled near its end. Its search runs on the server, once typing has
// paused for [_searchDelay].
const int _mosqueListPageSize = 30;
const Duration _searchDelay = Duration(milliseconds: 400);
// Orphanages and miqat mosques still load in one request, and their search
// filters what was loaded. The miqat endpoint ignores `page`, so it could not
// be paged anyway.
const int _listItemsLimit = 1000;
// How far, in meters, the map has to move from where its pins were fetched
// before stopping fetches new ones.
const double _mapRefetchDistance = 50;

const TextStyle _cityMenuTextStyle = TextStyle(fontSize: 14);
// MenuItemButton's default horizontal padding (12 + 12) plus DropdownMenu's
// input start gap (4), with a little slack so the widest label never wraps.
const double _cityMenuHorizontalPadding = 34;

/// Push this page with [SpecificMosqueRoute], which decides what leaving it
/// without confirming keeps.
class SpecificMosquePage extends StatefulWidget {
  final String slug;
  final List<Place> initialSelections;
  final String? title;
  final bool isEssentialProduct;

  const SpecificMosquePage({
    super.key,
    this.slug = 'mosques',
    this.initialSelections = const [],
    this.title,
    this.isEssentialProduct = false,
  });

  /// Orphanages and miqat mosques are picked from the list alone: the page
  /// shows no List/Map switcher, and builds and loads nothing for the map.
  bool get needMap => slug != 'orphanages' && slug != 'meqat_mosques';

  @override
  State<SpecificMosquePage> createState() => _SpecificMosquePageState();
}

/// The route [SpecificMosquePage] is pushed with.
///
/// Confirm completes it with the places picked. Leaving any other way — the
/// app bar arrow, the system back button, the iOS edge swipe — carries no
/// result, so the route asks the page what a back-out keeps, and that is the
/// same as Confirm: the selection as it now stands, with places added or
/// removed on the page, and an empty list after Clear All.
///
/// The one exception is a page that opened with nothing selected and is left
/// with nothing selected. That completes with null, so the caller's selection
/// stays as it was (an orphanage's "Most in need" choice, say).
class SpecificMosqueRoute extends MaterialPageRoute<List<Place>> {
  SpecificMosqueRoute({required super.builder});

  /// Supplied by the page once it is mounted.
  ValueGetter<List<Place>?>? _backOutResult;

  @override
  List<Place>? get currentResult => _backOutResult?.call();
}

class _SpecificMosquePageState extends State<SpecificMosquePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  // The list is loading its first page again, for a new search. Unlike
  // [_isLoading] this covers only the list, so the map stays mounted.
  bool _isReloadingList = false;
  int _listFetchGeneration = 0;
  String _searchQuery = '';
  Timer? _searchTimer;
  List<Place> _items = [];
  List<Place> _allMapItems = [];
  bool _isLoadingMapItems = true;
  int _mapFetchGeneration = 0;
  List<Place> _filteredItems = [];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _selectedItemsScrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  City? _selectedCity;
  List<City> _cities = [];

  GoogleMapController? _mapController;
  final List<Place> _selectedItemsList = [];
  Set<String> _favoriteMosqueIds = {};

  // Creating a GoogleMap blocks Android's main thread for a few seconds, and
  // touches queue up behind it. So the map, and the pins it shows, wait until
  // the map tab is first opened; after that the map stays mounted.
  int _shownTabIndex = 0;
  bool _mapTabOpened = false;
  bool _locationResolved = false;
  // Where the camera is, once it has moved; null while it is still where it
  // opened.
  LatLng? _mapCenter;
  // Where the shown (or loading) pins were fetched around; null until the
  // first fetch starts.
  LatLng? _mapItemsCenter;
  BitmapDescriptor? _mapPinIcon;
  BitmapDescriptor? _mapPinSelectedIcon;

  Future<void> _loadMapPinIcon() async {
    final mapPinIcon = await MapMarkerIcon.load();
    final mapPinSelectedIcon = await MapMarkerIcon.loadSelected();
    if (mounted) {
      setState(() {
        if (mapPinIcon != null) _mapPinIcon = mapPinIcon;
        if (mapPinSelectedIcon != null) {
          _mapPinSelectedIcon = mapPinSelectedIcon;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.needMap) _loadMapPinIcon();
    _selectedItemsList.addAll(widget.initialSelections);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
    _initData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is SpecificMosqueRoute) route._backOutResult = _backOutResult;
  }

  // The controller notifies both when a tab change starts and when its
  // animation ends; only the first needs a rebuild.
  void _onTabChanged() {
    final index = _tabController.index;
    if (index == _shownTabIndex) return;
    setState(() {
      _shownTabIndex = index;
      if (index == 1) _mapTabOpened = true;
    });
    _startMapItemsIfReady();
  }

  // The first map pins are fetched near the user, so they also wait for the
  // location lookup in [_initData]. After that the pins follow the camera;
  // see [_onCameraIdle].
  void _startMapItemsIfReady() {
    if (!_mapTabOpened || !_locationResolved || _mapItemsCenter != null) {
      return;
    }
    _fetchMapItems(_userLocation);
  }

  // Once the camera stops, the mosques nearest its new center replace the
  // pins. A stop close to where they were fetched (the opening GPS fix
  // settling, say) keeps them.
  void _onCameraIdle() {
    final center = _mapCenter;
    final fetchedAround = _mapItemsCenter;
    if (center == null || fetchedAround == null) return;
    final moved = Geolocator.distanceBetween(
      fetchedAround.latitude,
      fetchedAround.longitude,
      center.latitude,
      center.longitude,
    );
    if (moved < _mapRefetchDistance) return;
    _fetchMapItems(center);
  }

  /// What leaving without Confirm keeps; see [SpecificMosqueRoute].
  List<Place>? _backOutResult() =>
      widget.initialSelections.isEmpty && _selectedItemsList.isEmpty
      ? null
      : List.of(_selectedItemsList);

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isReloadingList &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchItems(isLoadMore: true);
  }

  // Every slug but these lists from /mosques, which pages and searches on the
  // server.
  bool get _isMosqueList =>
      widget.slug != 'orphanages' && widget.slug != 'meqat_mosques';

  int get _listPageSize =>
      _isMosqueList ? _mosqueListPageSize : _listItemsLimit;

  Position? _currentUserPosition;

  // Where the map opens: the user, or Riyadh when their location is unknown.
  LatLng get _userLocation => LatLng(
    _currentUserPosition?.latitude ?? AppStorage.userLatitude ?? 24.7136,
    _currentUserPosition?.longitude ?? AppStorage.userLongitude ?? 46.6753,
  );

  Future<void> _initData() async {
    _currentUserPosition = await _getUserLocation();
    _locationResolved = true;
    _startMapItemsIfReady();
    await _fetchFavorites();
    // Cities only fill the map's filter.
    if (widget.needMap) _fetchCities();
    await _fetchItems();
  }

  Future<void> _fetchCities() async {
    try {
      final response = await _apiService.getCities();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _cities = data
                .map((e) => City.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      // Ignore; the city filter simply stays empty.
    }
  }

  // Where the map goes for a picked city. Not the first pin loaded for it:
  // /mosques/miqat ignores the city filter, so that pin is the same for
  // every city.
  static LatLng? _cityCenter(City? city) {
    final latitude = city?.latitude;
    final longitude = city?.longitude;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  // Fetches the `_mapItemsLimit` mosques nearest [center], within the picked
  // city if there is one, in place of the pins the map showed before. That
  // they are the nearest relies on /mosques ordering what it returns by
  // distance from the coordinates it is sent. Only the mosque slugs reach the
  // map (see [SpecificMosquePage.needMap]), so only /mosques is asked.
  //
  // `citySelected` marks a fetch started by picking a city: it takes the old
  // pins down at once, since they may lie outside the new filter, and once
  // the results arrive it tells the user if the city has nothing to show, and
  // for a city without coordinates of its own it centers the map on the first
  // pin instead. Otherwise the old pins stay up until the new ones arrive.
  //
  // Each call starts a new generation. A fetch whose generation is no longer
  // current (the map moved on, or the city changed, while it was loading)
  // drops what it fetched, so only the latest pins are ever shown.
  Future<void> _fetchMapItems(
    LatLng center, {
    bool citySelected = false,
  }) async {
    final int generation = ++_mapFetchGeneration;
    final String? cityId = _selectedCity?.id;
    _mapItemsCenter = center;

    setState(() {
      if (citySelected) _allMapItems = [];
      _isLoadingMapItems = true;
    });

    dynamic response;
    try {
      response = await _apiService.getMosques(
        limit: _mapItemsLimit,
        latitude: center.latitude,
        longitude: center.longitude,
        cityId: cityId,
      );
    } catch (e) {
      if (mounted && generation == _mapFetchGeneration) {
        setState(() => _isLoadingMapItems = false);
      }
      return;
    }

    if (!mounted || generation != _mapFetchGeneration) return;

    if (response.statusCode != 200 || response.data['success'] != true) {
      setState(() => _isLoadingMapItems = false);
      return;
    }

    final List<dynamic> data = response.data['data'] ?? [];
    final List<Place> newItems = data
        .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _allMapItems = newItems;
      _isLoadingMapItems = false;
    });

    if (!citySelected) return;
    if (newItems.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.no_mosques_available_in_selected_city,
        isError: true,
      );
    } else if (_cityCenter(_selectedCity) == null) {
      final first = newItems.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(first.latitude, first.longitude),
          12.0,
        ),
      );
    }
  }

  Future<void> _fetchFavorites() async {
    // Favourites belong to a customer account. A guest can pick places from
    // this screen, but has no saved list to mark them against.
    if (AuthStorage.isGuest) return;
    try {
      final response = await _apiService.getFavoriteMosques();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            // The API returns Mosque objects directly in the data array, so their ID is just 'id'
            _favoriteMosqueIds = data.map((e) => e['id'].toString()).toSet();
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final isFav = _favoriteMosqueIds.contains(id);
    setState(() {
      if (isFav) {
        _favoriteMosqueIds.remove(id);
      } else {
        _favoriteMosqueIds.add(id);
      }
    });

    try {
      if (isFav) {
        await _apiService.deleteFavoriteMosque(id);
      } else {
        await _apiService.addFavoriteMosque(id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isFav) {
            _favoriteMosqueIds.add(id);
          } else {
            _favoriteMosqueIds.remove(id);
          }
        });
        String errorMessage = AppLocalizations.of(
          context,
        )!.failed_to_update_favorite;
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedItemsScrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    // The controller also notifies when only the cursor moves.
    if (query == _searchQuery) return;
    _searchQuery = query;
    if (_isMosqueList) {
      _searchTimer?.cancel();
      _searchTimer = Timer(_searchDelay, _fetchItems);
    } else {
      setState(_filterItems);
    }
  }

  // The server has already searched the mosque list, so only the places
  // loaded in one go are filtered here.
  void _filterItems() {
    final query = _searchQuery.toLowerCase();
    if (_isMosqueList || query.isEmpty) {
      _filteredItems = _items;
      return;
    }
    _filteredItems = _items.where((m) {
      final nameEn = m.name.toLowerCase();
      final nameAr = m.nameAr.toLowerCase();
      final address = m.address.toLowerCase();
      return nameEn.contains(query) ||
          nameAr.contains(query) ||
          address.contains(query);
    }).toList();
  }

  // Loading the first page (again, for a new search) starts a new generation,
  // and a fetch whose generation is no longer current drops what it fetched:
  // results for an older search never land in the list.
  Future<void> _fetchItems({bool isLoadMore = false}) async {
    final int generation = isLoadMore
        ? _listFetchGeneration
        : ++_listFetchGeneration;
    if (!isLoadMore) {
      if (!mounted) return;
      setState(() {
        _isReloadingList = true;
        _currentPage = 1;
        _hasMore = true;
        _items.clear();
      });
    }

    // A page only counts as loaded once it arrives, so one that fails is
    // asked for again on the next scroll rather than skipped.
    final int page = isLoadMore ? _currentPage + 1 : 1;

    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages(
          page: page,
          limit: _listPageSize,
        );
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques(
          page: page,
          limit: _listPageSize,
        );
      } else {
        response = await _apiService.getMosques(
          page: page,
          limit: _listPageSize,
          latitude: _currentUserPosition?.latitude ?? AppStorage.userLatitude,
          longitude:
              _currentUserPosition?.longitude ?? AppStorage.userLongitude,
          search: _searchQuery,
        );
      }

      if (!mounted || generation != _listFetchGeneration) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final Map<String, dynamic>? meta = response.data['meta'];

        setState(() {
          List<Place> newItems = [];
          if (widget.slug == 'orphanages') {
            newItems = data
                .map((e) => Orphanage.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (widget.slug == 'meqat_mosques') {
            newItems = data
                .map((e) => MeqatMosque.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            newItems = data
                .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          if (isLoadMore) {
            _items.addAll(newItems);
          } else {
            _items = newItems;
          }
          _currentPage = page;

          if (meta != null) {
            final int totalPages = meta['totalPages'] ?? 1;
            _hasMore = page < totalPages;
          } else {
            // Without paging info, a short page is the last one. The miqat
            // endpoint sends none and ignores `page`, so asking for more
            // would just append the same mosques again.
            _hasMore = newItems.length == _listPageSize;
          }

          _filterItems();
          _isLoading = false;
          _isReloadingList = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isReloadingList = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted || generation != _listFetchGeneration) return;
      setState(() {
        _isLoading = false;
        _isReloadingList = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String title;
    String subtitle;
    String listTabText;

    if (widget.slug == 'orphanages') {
      title =
          widget.title ??
          (AppLocalizations.of(context)!.choose_specific_orphanage);
      subtitle = AppLocalizations.of(
        context,
      )!.select_an_orphanage_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_orphanages;
    } else if (widget.slug == 'meqat_mosques') {
      title =
          widget.title ??
          (AppLocalizations.of(context)!.choose_specific_meqat_mosque);
      subtitle = AppLocalizations.of(
        context,
      )!.select_a_mosque_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_meqat_mosques;
    } else if (widget.isEssentialProduct) {
      title = widget.title ?? (AppLocalizations.of(context)!.choose_mosques);
      subtitle = AppLocalizations.of(context)!.select_mosques_to_deliver_to;
      listTabText = AppLocalizations.of(context)!.list_of_mosques;
    } else {
      title =
          widget.title ??
          (AppLocalizations.of(context)!.choose_specific_mosque);
      subtitle = AppLocalizations.of(
        context,
      )!.select_a_mosque_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_mosques;
    }

    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildDynamicHeader(isAr),
                    ),
                    // Without it the controller stays on the list tab, so the
                    // map is never opened, built or loaded.
                    if (widget.needMap)
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Material(
                          color: const Color(0xFFE5E9EC),
                          borderRadius: BorderRadius.circular(25),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: 50,
                            child: TabBar(
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              dividerHeight: 0,
                              dividerColor: Colors.transparent,
                              controller: _tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppColors.buttonBlueDark,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: AppColors.buttonBlueDark,
                              ),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              tabs: [
                                Tab(text: listTabText),
                                Tab(
                                  text: AppLocalizations.of(
                                    context,
                                  )!.choose_from_map,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: _isLoading
                          ? _buildShimmerLoading()
                          : Stack(
                              children: [
                                // Once opened, the Map stays mounted and rendered underneath to prevent PlatformView from clearing its buffers
                                if (_mapTabOpened) _buildMapTab(isAr),
                                // The List tab is overlaid on top of the Map when active, with an opaque background
                                if (_tabController.index == 0)
                                  Container(
                                    color: Colors.white,
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: _isReloadingList
                                        ? _buildShimmerLoading()
                                        : _buildListTab(isAr),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedItemsList.isNotEmpty) _buildBottomBar(isAr),
        ],
      ),
    );
  }

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    await AppStorage.saveUserLocation(position.latitude, position.longitude);
    return position;
  }

  // A GPS fix can take seconds. With [keepCity], a city picked while it was
  // pending keeps the camera, rather than being pulled back to the user.
  Future<void> _getUserLocationAndMoveCamera({bool keepCity = false}) async {
    Position? position = await _getUserLocation();
    if (keepCity && _selectedCity != null) return;
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          12.0,
        ),
      );
    }
  }

  Widget _buildDynamicHeader(bool isAr) {
    if (_tabController.index == 0) {
      return SizedBox(
        height: 50,
        child: TextField(
          cursorColor: AppColors.buttonBlueDark,
          style: const TextStyle(color: AppColors.buttonBlueDark, fontSize: 14),
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.slug == 'orphanages'
                ? (AppLocalizations.of(context)!.search_orphanages)
                : widget.slug == 'meqat_mosques'
                ? (AppLocalizations.of(context)!.search_meqat_mosques)
                : (AppLocalizations.of(context)!.search_mosques),
            hintStyle: TextStyle(
              color: AppColors.buttonBlueDark.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.buttonBlueDark,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.buttonBlueDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.buttonBlueDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.buttonBlueDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    } else {
      final entries = _cities.map((city) {
        return DropdownMenuEntry<City>(
          value: city,
          label: city.localizedName(isAr),
          style: MenuItemButton.styleFrom(
            foregroundColor: AppColors.buttonBlueDark,
            textStyle: _cityMenuTextStyle,
          ),
        );
      }).toList();

      // The button spans the full width (expandedInsets), which would otherwise
      // also be the popup's minimum width. Measuring the longest label lets the
      // popup shrink to just fit it.
      final textDirection = Directionality.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      // Measure at the weight the labels actually render at, or the popup ends
      // up too narrow for them once the bold text setting is on.
      final measuredStyle = MediaQuery.boldTextOf(context)
          ? _cityMenuTextStyle.merge(
              const TextStyle(fontWeight: FontWeight.bold),
            )
          : _cityMenuTextStyle;
      double longestLabelWidth = 0;
      for (final entry in entries) {
        final painter = TextPainter(
          text: TextSpan(text: entry.label, style: measuredStyle),
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();
        longestLabelWidth = math.max(longestLabelWidth, painter.width);
      }

      // DropdownMenu anchors its popup below the button, unlike DropdownButton
      // which overlays the menu on top of it.
      return DropdownMenu<City>(
        expandedInsets: EdgeInsets.zero,
        width: longestLabelWidth + _cityMenuHorizontalPadding,
        initialSelection: _selectedCity,
        requestFocusOnTap: false,
        enableSearch: false,
        menuHeight: 260,
        hintText: AppLocalizations.of(context)!.select_city,
        textStyle: const TextStyle(
          color: AppColors.buttonBlueDark,
          fontSize: 14,
        ),
        trailingIcon: const Icon(
          Icons.arrow_drop_down,
          color: AppColors.buttonBlueDark,
        ),
        selectedTrailingIcon: const Icon(
          Icons.arrow_drop_up,
          color: AppColors.buttonBlueDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          constraints: const BoxConstraints(minHeight: 50, maxHeight: 50),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintStyle: TextStyle(
            color: AppColors.buttonBlueDark.withValues(alpha: 0.8),
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.buttonBlueDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.buttonBlueDark,
              width: 1.5,
            ),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        dropdownMenuEntries: entries,
        onSelected: (val) {
          setState(() {
            _selectedCity = val;
          });
          final center = _cityCenter(val);
          if (center != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(center, 12.0),
            );
          }
          _fetchMapItems(
            center ?? _mapCenter ?? _userLocation,
            citySelected: true,
          );
        },
      );
    }
  }

  Widget _buildListTab(bool isAr) {
    if (_filteredItems.isEmpty) {
      String emptyText;
      if (widget.slug == 'orphanages') {
        emptyText = AppLocalizations.of(context)!.no_orphanages_found;
      } else if (widget.slug == 'meqat_mosques') {
        emptyText = AppLocalizations.of(context)!.no_meqat_mosques_found;
      } else {
        emptyText = AppLocalizations.of(context)!.no_mosques_found;
      }
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: _filteredItems.length + (_isLoadingMore ? 3 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index >= _filteredItems.length) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: _buildShimmerItem(),
          );
        }
        final item = _filteredItems[index];

        bool isHighNeed = false;
        if (item is Orphanage) {
          isHighNeed = item.isHighNeed;
        }

        final isSelected = _selectedItemsList.any((m) => m.id == item.id);

        return mosqueCard(
          context: context,
          isSelected: isSelected,
          item: item,
          slug: widget.slug,
          onTapCard: () {
            setState(() {
              if (_selectedItemsList.any((m) => m.id == item.id)) {
                _selectedItemsList.removeWhere((m) => m.id == item.id);
              } else {
                _selectedItemsList.add(item);
              }
            });
          },
          isAr: isAr,
          isHighNeed: isHighNeed,
          // Favouriting needs a customer account, so a guest gets no heart.
          toggleFavorite: AuthStorage.isGuest
              ? null
              : () => _toggleFavorite(item.id),
          favoriteMosqueIds: _favoriteMosqueIds,
          currentLat: _currentUserPosition?.latitude ?? AppStorage.userLatitude,
          currentLong:
              _currentUserPosition?.longitude ?? AppStorage.userLongitude,
        );
      },
    );
  }

  Widget _buildMapTab(bool isAr) {
    // Picked places keep their pins once the map moves away from them.
    final pinnedItems = [
      ..._allMapItems,
      ..._selectedItemsList.where(
        (selected) => !_allMapItems.any((item) => item.id == selected.id),
      ),
    ];
    final Set<Marker> markers = pinnedItems.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: _selectedItemsList.any((m) => m.id == item.id)
            ? (_mapPinSelectedIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ))
            : (_mapPinIcon ?? BitmapDescriptor.defaultMarkerWithHue(207.0)),
        infoWindow: InfoWindow(
          title: item.localizedName(isAr),
          snippet: item.address,
        ),
        onTap: () {
          setState(() {
            if (_selectedItemsList.any((m) => m.id == item.id)) {
              _selectedItemsList.removeWhere((m) => m.id == item.id);
            } else {
              _selectedItemsList.add(item);
            }
          });
        },
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLocation,
            zoom: 12,
          ),
          markers: markers,
          onCameraMove: (position) => _mapCenter = position.target,
          onCameraIdle: _onCameraIdle,
          onMapCreated: (controller) {
            _mapController = controller;
            final center =
                _cityCenter(_selectedCity) ??
                (_selectedCity != null && _allMapItems.isNotEmpty
                    ? LatLng(
                        _allMapItems.first.latitude,
                        _allMapItems.first.longitude,
                      )
                    : null);
            if (center != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(center, 12.0),
              );
            } else {
              _getUserLocationAndMoveCamera(keepCity: true);
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled:
              false, // Disabled default to avoid overlap with our custom one
          // Android-only control, drawn in the same bottom-right corner as
          // our location button. Pinch to zoom still works.
          zoomControlsEnabled: false,
         

          mapToolbarEnabled: false,

        ),
        Positioned(
          bottom: 24,
          right: isAr ? null : 24,
          left: isAr ? 24 : null,
          child: FloatingActionButton(
            heroTag: 'customMyLocationBtn',
            backgroundColor: Colors.white,
            mini: false,
            onPressed: _getUserLocationAndMoveCamera,
            child: const Icon(
              Icons.my_location,
              color: AppColors.buttonBlueDark,
            ),
          ),
        ),
        // A bar rather than a cover over the map: pins load each time the map
        // stops, and the map has to stay usable while they do.
        if (_isLoadingMapItems)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.buttonBlueDark,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(bool isAr) {
    // Beyond four tiles the list scrolls, so the thumb earns its keep.
    final isScrollable = _selectedItemsList.length > _maxVisibleSelectedTiles;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caps the list at 4 tiles tall, scrolling beyond that.
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight:
                  _maxVisibleSelectedTiles * _selectedTileHeight +
                  (_maxVisibleSelectedTiles - 1) * _selectedTileGap,
            ),
            // The scrollbar sides with the text direction on its own: right in
            // English, left in Arabic.
            child: Scrollbar(
              controller: _selectedItemsScrollController,
              thumbVisibility: isScrollable,
              child: ListView.separated(
                controller: _selectedItemsScrollController,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                // Keep the tiles clear of the thumb once it is showing.
                padding: isScrollable
                    ? const EdgeInsetsDirectional.only(end: _scrollbarGutter)
                    : EdgeInsets.zero,
                itemCount: _selectedItemsList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: _selectedTileGap),
                itemBuilder: (context, index) {
                  final item = _selectedItemsList[index];
                  final isFavorite = _favoriteMosqueIds.contains(item.id);
                  return Container(
                    height: _selectedTileHeight,
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.buttonBlueDark.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.localizedName(isAr),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.buttonBlueDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.slug != 'orphanages' &&
                            !AuthStorage.isGuest)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _toggleFavorite(item.id),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22,
                              color: isFavorite
                                  ? Colors.redAccent
                                  : AppColors.buttonBlueDark,
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _selectedItemsList.remove(item);
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedItemsList.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.clear_all),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedItemsList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.confirm_selection,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: SizedBox(
              height: 73,
              width: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 120, height: 16, color: Colors.white),
                    if (widget.slug != 'orphanages')
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          return _buildShimmerItem();
        },
      ),
    );
  }
}
