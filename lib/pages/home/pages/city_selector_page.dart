import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:dio/dio.dart';
import '../../../api/apis.dart';
import '../../../models/city.dart';

class CitySelectorPage extends StatefulWidget {
  const CitySelectorPage({Key? key}) : super(key: key);

  @override
  State<CitySelectorPage> createState() => _CitySelectorPageState();
}

class _CitySelectorPageState extends State<CitySelectorPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final response = await _apiService.getCities();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _cities = data.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isAr ? 'اختر مدينة' : 'Select a City'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: WaterLoadingIndicator(size: 30))
          : _cities.isEmpty
              ? Center(child: Text(isAr ? 'لا توجد مدن' : 'No cities found'))
              : ListView.separated(
                  itemCount: _cities.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return ListTile(
                      title: Text(
                        city.localizedName(isAr),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        // Return selected city to previous screen
                        Navigator.of(context).pop(city);
                      },
                    );
                  },
                ),
    );
  }
}
