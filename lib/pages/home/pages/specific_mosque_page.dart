import 'dart:developer';

import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../api/apis.dart';
import '../../../models/mosque.dart';
import '../../../models/meqat_mosque.dart';
import '../../../models/orphanage.dart';
import '../../../models/place.dart';
import '../../../utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class SpecificMosquePage extends StatefulWidget {
  final String slug;
  final List<Place> initialSelections;
  final String? title;

  const SpecificMosquePage({
    super.key,
    this.slug = 'mosques',
    this.initialSelections = const [],
    this.title,
  });

  @override
  State<SpecificMosquePage> createState() => _SpecificMosquePageState();
}

class _SpecificMosquePageState extends State<SpecificMosquePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Place> _items = [];
  List<Place> _allMapItems = [];
  bool _isLoadingMapItems = true;
  List<Place> _filteredItems = [];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Map<String, dynamic>? _selectedCity;

  final List<Map<String, dynamic>> _cityFilters = [
    {'name': 'Makkah', 'nameAr': 'مكة المكرمة', 'lat': 21.3891, 'lng': 39.8579},
    {
      'name': 'Madina',
      'nameAr': 'المدينة المنورة',
      'lat': 24.5247,
      'lng': 39.5692,
    },
    {'name': 'Riyadh', 'nameAr': 'الرياض', 'lat': 24.7136, 'lng': 46.6753},
    {'name': 'Jeddah', 'nameAr': 'جدة', 'lat': 21.4858, 'lng': 39.1925},
    {'name': 'Sakaka', 'nameAr': 'سكاكا', 'lat': 29.9697, 'lng': 40.2064},
    {'name': 'Abha', 'nameAr': 'أبها', 'lat': 18.2164, 'lng': 42.5053},
    {'name': 'Taif', 'nameAr': 'الطائف', 'lat': 21.2643, 'lng': 40.4022},
  ];

  GoogleMapController? _mapController;
  final List<Place> _selectedItemsList = [];
  List<String> _favoriteMosqueIds = [];

  @override
  void initState() {
    super.initState();
    _selectedItemsList.addAll(widget.initialSelections);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
    _initData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchItems(isLoadMore: true);
  }

  Position? _currentUserPosition;

  Future<void> _initData() async {
    _currentUserPosition = await _getUserLocation();
    await _fetchFavorites();
    _fetchAllMapItems();
    await _fetchItems();
  }

  Future<void> _fetchAllMapItems() async {
    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages(page: 1, limit: 1000);
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques(page: 1, limit: 1000);
      } else {
        response = await _apiService.getMosques(
          page: 1,
          limit: 1000,
          latitude: _currentUserPosition?.latitude,
          longitude: _currentUserPosition?.longitude,
        );
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            if (widget.slug == 'orphanages') {
              _allMapItems = data
                  .map((e) => Orphanage.fromJson(e as Map<String, dynamic>))
                  .toList();
            } else if (widget.slug == 'meqat_mosques') {
              _allMapItems = data
                  .map((e) => MeqatMosque.fromJson(e as Map<String, dynamic>))
                  .toList();
            } else {
              _allMapItems = data
                  .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            _isLoadingMapItems = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMapItems = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMapItems = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final response = await _apiService.getFavoriteMosques();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            // The API returns Mosque objects directly in the data array, so their ID is just 'id'
            _favoriteMosqueIds = data.map((e) => e['id'].toString()).toList();
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
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((m) {
          final nameEn = m.name.toLowerCase();
          final nameAr = m.nameAr.toLowerCase();
          final address = m.address.toLowerCase();
          return nameEn.contains(query) ||
              nameAr.contains(query) ||
              address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchItems({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _items.clear();
      });
    }

    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages(
          page: _currentPage,
          limit: 1000,
        );
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques(
          page: _currentPage,
          limit: 1000,
        );
      } else {
        response = await _apiService.getMosques(
          page: _currentPage,
          limit: 1000,
          latitude: _currentUserPosition?.latitude,
          longitude: _currentUserPosition?.longitude,
        );
      }

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

          if (meta != null) {
            final int totalPages = meta['totalPages'] ?? 1;
            _hasMore = _currentPage < totalPages;
          } else {
            _hasMore = newItems.isNotEmpty;
          }

          _onSearchChanged(); // update _filteredItems
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
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
      backgroundColor: Colors.white,
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
            child: Column(
              children: [
                Container(
                  color: AppColors.buttonBlueDark,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildDynamicHeader(isAr),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.buttonBlueDark,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.buttonBlueDark,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: listTabText),
                    Tab(text: AppLocalizations.of(context)!.choose_from_map),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [_buildListTab(isAr), _buildMapTab(isAr)],
                        ),
                ),
              ],
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

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getUserLocationAndMoveCamera() async {
    Position? position = await _getUserLocation();
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
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.indicatorGrey),
        ),
        child: TextField(
          cursorColor: AppColors.buttonBlueDark,

          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.slug == 'orphanages'
                ? (AppLocalizations.of(context)!.search_orphanages)
                : widget.slug == 'meqat_mosques'
                ? (AppLocalizations.of(context)!.search_meqat_mosques)
                : (AppLocalizations.of(context)!.search_mosques),
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.indicatorGrey),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(15),
            hint: Text(
              AppLocalizations.of(context)!.select_city,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            value: _selectedCity,
            items: _cityFilters.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Text(
                  isAr ? city['nameAr'] : city['name'],
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCity = val;
              });
              if (val != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(val['lat'], val['lng']),
                    12.0,
                  ),
                );
              }
            },
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          const Divider(height: 16, color: Colors.transparent),
      itemBuilder: (context, index) {
        if (index == _filteredItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: WaterLoadingIndicator(size: 30),
            ),
          );
        }
        final item = _filteredItems[index];
        log(
          "Place: ${item.id}, ${item.name}, ${item.nameAr}, ${item.latitude}, ${item.longitude}, ${item.address}, ${item.image}",
        );

        bool isHighNeed = false;
        if (item is Orphanage) {
          isHighNeed = item.isHighNeed;
        }

        final isSelected = _selectedItemsList.any((m) => m.id == item.id);
        return Stack(
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              color: isSelected ? const Color(0xFFE8F4FA) : Colors.white,
              elevation: isSelected ? 5 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.buttonBlue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedItemsList.any((m) => m.id == item.id)) {
                      _selectedItemsList.removeWhere((m) => m.id == item.id);
                    } else {
                      _selectedItemsList.add(item);
                    }
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Image edge to edge
                    if (item.image != null && item.image!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: item.image!,
                        height: 140,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 140,
                          color: Colors.grey[200],
                          child: const Center(
                            child: WaterLoadingIndicator(size: 30),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 140,
                          color: Colors.grey[100],
                          child: Icon(
                            widget.slug == 'orphanages'
                                ? Icons.home
                                : Icons.mosque,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: Icon(
                          widget.slug == 'orphanages'
                              ? Icons.home
                              : Icons.mosque,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),

                    // Content below image
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.localizedName(isAr),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.slug != 'orphanages')
                                InkWell(
                                  onTap: () => _toggleFavorite(item.id),
                                  radius: 100,
                                  child: Material(
                                    shape: CircleBorder(),
                                    color: Colors.white,
                                    elevation: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        _favoriteMosqueIds.contains(item.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            _favoriteMosqueIds.contains(item.id)
                                            ? Colors.redAccent
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.address.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
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
              ),
            ),
            if (isHighNeed)
              Positioned(
                top: 15,
                right: isAr ? null : 10,
                left: isAr ? 10 : null,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_outlined,
                        color: AppColors.buttonBlue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.high_need,
                        style: const TextStyle(
                          color: AppColors.buttonBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapTab(bool isAr) {
    if (_isLoadingMapItems) {
      return const Center(child: WaterLoadingIndicator(size: 30));
    }

    final Set<Marker> markers = _allMapItems.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedItemsList.any((m) => m.id == item.id)
              ? BitmapDescriptor.hueGreen
              : 207.0,
        ),
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
          initialCameraPosition: const CameraPosition(
            target: LatLng(24.7136, 46.6753),
            zoom: 12,
          ),
          markers: markers,
          onMapCreated: (controller) {
            _mapController = controller;
            if (_selectedCity != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_selectedCity!['lat'], _selectedCity!['lng']),
                  12.0,
                ),
              );
            } else {
              _getUserLocationAndMoveCamera();
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled:
              false, // Disabled default to avoid overlap with our custom one
          zoomControlsEnabled: true,
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
      ],
    );
  }

  Widget _buildBottomBar(bool isAr) {
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: _selectedItemsList.length,
              itemBuilder: (context, index) {
                final item = _selectedItemsList[index];
                return Container(
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.buttonBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.localizedName(isAr),
                        style: const TextStyle(
                          color: AppColors.buttonBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItemsList.remove(item);
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                    ],
                  ),
                );
              },
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const Divider(height: 16, color: Colors.transparent),
        itemBuilder: (context, index) {
          return Card(
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 140, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.slug != 'orphanages')
                        const Icon(Icons.favorite, color: Colors.white),
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
}
