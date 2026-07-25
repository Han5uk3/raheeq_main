import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import '../../../models/city.dart';
import '../../../utils/colors.dart';
import '../../../utils/rtl_helpers.dart';

class CitySelectorDialog extends StatefulWidget {
  final List<City> initialSelections;
  final List<City> allCities;

  const CitySelectorDialog({
    super.key,
    this.initialSelections = const [],
    this.allCities = const [],
  });

  @override
  State<CitySelectorDialog> createState() => _CitySelectorDialogState();
}

class _CitySelectorDialogState extends State<CitySelectorDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<City> _cities = [];
  final List<City> _selectedItemsList = [];

  @override
  void initState() {
    super.initState();
    _selectedItemsList.addAll(widget.initialSelections);

    if (widget.allCities.isNotEmpty) {
      _cities = widget.allCities;
      _isLoading = false;
    } else {
      _fetchCities();
    }
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

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      backArrowIcon(context),
                      size: 22,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.choose_cities,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cities content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: WaterLoadingIndicator(size: 30)),
              )
            else if (_cities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.no_cities_found,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _cities.map((city) {
                      final isSelected = _selectedItemsList.any(
                        (c) => c.id == city.id,
                      );

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedItemsList.removeWhere(
                                (c) => c.id == city.id,
                              );
                            } else {
                              _selectedItemsList.add(city);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.buttonBlueDark
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.buttonBlueDark
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            city.localizedName(isAr),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (_selectedItemsList.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(<City>[]);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.clear_all,
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
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.continue_btn,
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
          ],
        ),
      ),
    );
  }
}
