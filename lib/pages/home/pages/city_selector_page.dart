import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import '../../../api/apis.dart';
import '../../../models/city.dart';
import '../../../utils/colors.dart';

class CitySelectorPage extends StatefulWidget {
  final List<City> initialSelections;

  const CitySelectorPage({
    super.key,
    this.initialSelections = const [],
  });

  @override
  State<CitySelectorPage> createState() => _CitySelectorPageState();
}

class _CitySelectorPageState extends State<CitySelectorPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<City> _cities = [];
  List<City> _filteredCities = [];
  
  final TextEditingController _searchController = TextEditingController();
  final List<City> _selectedItemsList = [];

  @override
  void initState() {
    super.initState();
    _selectedItemsList.addAll(widget.initialSelections);
    _searchController.addListener(_onSearchChanged);
    _fetchCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _cities;
      } else {
        _filteredCities = _cities.where((c) {
          final nameEn = c.name.toLowerCase();
          final nameAr = c.nameAr.toLowerCase();
          return nameEn.contains(query) || nameAr.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchCities() async {
    try {
      final response = await _apiService.getCities();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _cities = data.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
            _filteredCities = List.from(_cities);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBottomBar(bool isAr) {
    if (_selectedItemsList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedItemsList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      backgroundColor: const Color(0xFFE8F4FA),
                      side: BorderSide.none,
                      label: Text(
                        item.localizedName(isAr),
                        style: const TextStyle(
                          color: AppColors.buttonBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedItemsList.removeWhere((m) => m.id == item.id);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedItemsList.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isAr ? 'إزالة التحديد' : 'Clear All',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'اختر مدناً' : 'Choose Cities';
    final subtitle = isAr ? 'اختر المدن الأكثر احتياجاً' : 'Select the most needy cities';

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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: isAr ? 'ابحث عن مدينة...' : 'Search for a city...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: WaterLoadingIndicator(size: 30))
                      : _filteredCities.isEmpty
                          ? Center(child: Text(isAr ? 'لا توجد مدن' : 'No cities found'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredCities.length,
                              separatorBuilder: (context, index) => const Divider(height: 16, color: Colors.transparent),
                              itemBuilder: (context, index) {
                                final city = _filteredCities[index];
                                final isSelected = _selectedItemsList.any((c) => c.id == city.id);
                                return Card(
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
                                        if (_selectedItemsList.any((c) => c.id == city.id)) {
                                          _selectedItemsList.removeWhere((c) => c.id == city.id);
                                        } else {
                                          _selectedItemsList.add(city);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.location_city,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              city.localizedName(isAr),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.buttonBlue,
                                              size: 28,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isAr),
    );
  }
}
