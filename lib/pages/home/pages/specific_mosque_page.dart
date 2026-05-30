import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../api/apis.dart';
import '../../../models/mosque.dart';
import '../../../models/meqat_mosque.dart';
import '../../../models/orphanage.dart';
import '../../../models/place.dart';
import '../../../utils/colors.dart';

class SpecificMosquePage extends StatefulWidget {
  final String slug;
  const SpecificMosquePage({super.key, this.slug = 'mosques'});

  @override
  State<SpecificMosquePage> createState() => _SpecificMosquePageState();
}

class _SpecificMosquePageState extends State<SpecificMosquePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Place> _items = [];
  List<Place> _filteredItems = [];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

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
  Place? _selectedItem;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
    _fetchItems();
  }

  @override
  void dispose() {
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

  Future<void> _fetchItems() async {
    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages();
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques();
      } else {
        response = await _apiService.getMosques();
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          if (widget.slug == 'orphanages') {
            _items = data
                .map((e) => Orphanage.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (widget.slug == 'meqat_mosques') {
            _items = data
                .map((e) => MeqatMosque.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            _items = data
                .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          _filteredItems = List.from(_items);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String title;
    String subtitle;
    String listTabText;

    if (widget.slug == 'orphanages') {
      title = isAr ? 'اختر دار أيتام محددة' : 'Choose Specific Orphanage';
      subtitle = isAr
          ? 'اختر داراً لإيصال المياه إليها'
          : 'Select an orphanage to deliver water to';
      listTabText = isAr ? 'قائمة دور الأيتام' : 'List of Orphanages';
    } else if (widget.slug == 'meqat_mosques') {
      title = isAr ? 'اختر ميقات محدد' : 'Choose Specific Meqat Mosque';
      subtitle = isAr
          ? 'اختر مسجداً لإيصال المياه إليه'
          : 'Select a mosque to deliver water to';
      listTabText = isAr ? 'قائمة المواقيت' : 'List of Meqat mosques';
    } else {
      title = isAr ? 'اختر مسجداً محدداً' : 'Choose Specific Mosque';
      subtitle = isAr
          ? 'اختر مسجداً لإيصال المياه إليه'
          : 'Select a mosque to deliver water to';
      listTabText = isAr ? 'قائمة المساجد' : 'List of Mosques';
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
                  color: const Color(0x4D91E3FE),
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
                    Tab(text: isAr ? 'الاختيار من الخريطة' : 'Choose from Map'),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: WaterLoadingIndicator(size: 30))
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [_buildListTab(isAr), _buildMapTab(isAr)],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.slug == 'orphanages'
                ? (isAr ? 'بحث في دور الأيتام...' : 'Search orphanages...')
                : widget.slug == 'meqat_mosques'
                ? (isAr ? 'بحث في المواقيت...' : 'Search meqat mosques...')
                : (isAr ? 'بحث في المساجد...' : 'Search mosques...'),
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
              isAr ? 'اختر المدينة' : 'Select city',
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
        emptyText = isAr ? 'لا توجد دور أيتام' : 'No orphanages found';
      } else if (widget.slug == 'meqat_mosques') {
        emptyText = isAr ? 'لا توجد مواقيت' : 'No meqat mosques found';
      } else {
        emptyText = isAr ? 'لا توجد مساجد' : 'No mosques found';
      }
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 16, color: Colors.transparent),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];

        bool isHighNeed = false;
        if (item is Orphanage) {
          isHighNeed = item.isHighNeed;
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop(item);
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
                        widget.slug == 'orphanages' ? Icons.home : Icons.mosque,
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
                      widget.slug == 'orphanages' ? Icons.home : Icons.mosque,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.localizedName(isAr),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (item.address.isNotEmpty)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,

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
                          if (true)
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.buttonBlue.withValues(
                                  alpha: .2,
                                ),
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
                                    isAr ? 'الأكثر احتياجاً' : 'High Need',
                                    style: const TextStyle(
                                      color: AppColors.buttonBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
        );
      },
    );
  }

  Widget _buildMapTab(bool isAr) {
    final Set<Marker> markers = _items.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(207.0),
        infoWindow: InfoWindow(
          title: item.localizedName(isAr),
          snippet: item.address,
        ),
        onTap: () {
          setState(() {
            _selectedItem = item;
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
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
        if (_selectedItem != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4A7B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.slug == 'orphanages'
                              ? Icons.home
                              : Icons.mosque,
                          color: const Color(0xFF0F4A7B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedItem!.localizedName(isAr),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedItem!.address.isNotEmpty)
                              Text(
                                _selectedItem!.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _selectedItem = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedItem);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4A7B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
