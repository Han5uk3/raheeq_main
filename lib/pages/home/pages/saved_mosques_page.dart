import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/mosque.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class SavedMosquesPage extends StatefulWidget {
  const SavedMosquesPage({super.key});

  @override
  State<SavedMosquesPage> createState() => _SavedMosquesPageState();
}

class _SavedMosquesPageState extends State<SavedMosquesPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Place> _savedMosques = [];
  final List<Place> _selectedItemsList = [];
  String? _errorMessage;

  // A synthetic Category representing mosques for the order queue
  static const _mosquesCategory = Category(
    id: 'specific_mosque',
    slug: 'specific_mosque',
    labelEn: 'Choose Specific Mosque',
    labelAr: 'مساجد',
    image: '',
    sortOrder: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchSavedMosques();
  }

  Future<void> _fetchSavedMosques() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getFavoriteMosques();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _savedMosques = data.map((e) {
            return Mosque.fromJson(e as Map<String, dynamic>);
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load saved mosques.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred while loading saved mosques.";
      });
    }
  }

  Future<void> _removeFavorite(Place item) async {
    try {
      setState(() {
        _savedMosques.removeWhere((m) => m.id == item.id);
      });
      final res = await _apiService.deleteFavoriteMosque(item.id);
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: (res.data is Map && res.data['message'] != null)
              ? res.data['message']
              : AppLocalizations.of(context)!.removed_from_saved(item.name),
        );
      }
    } catch (e) {
      // Re-fetch to restore state if deletion fails
      _fetchSavedMosques();
      if (mounted) {
        String errorMessage = AppLocalizations.of(
          context,
        )!.failed_to_remove_mosque;
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

  void _toggleSelection(Place item) {
    setState(() {
      if (_selectedItemsList.any((m) => m.id == item.id)) {
        _selectedItemsList.removeWhere((m) => m.id == item.id);
      } else {
        _selectedItemsList.add(item);
      }
    });
  }

  void _confirmSelection() {
    final realCategory = HomeTab.cachedCategories.firstWhere(
      (c) => c.slug == 'specific_mosque',
      orElse: () => _mosquesCategory,
    );

    for (var item in _selectedItemsList) {
      HomeTab.scheduleMosqueItem(
        SelectedCategoryItem(
          category: realCategory,
          optionType: 'specific',
          specificData: item,
        ),
      );
    }

    HomeScreen.switchTabNotifier.value = 0;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                children: [
                  CustomAppBar(
                    hasBackgroundColor: true,
                    isStartAligned: true,
                    title: AppLocalizations.of(context)!.saved_mosques,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.your_favorite_mosques,
                    showBackButton: true,
                    onBackTap: () => Navigator.pop(context),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    color: const Color(0x4D91E3FE),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: _isLoading
                            ? SizedBox(
                                key: const ValueKey('loader'),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: const Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: WaterLoadingIndicator(size: 30),
                                  ),
                                ),
                              )
                            : _errorMessage != null
                            ? SizedBox(
                                key: const ValueKey('error'),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: Center(child: Text(_errorMessage!)),
                              )
                            : _savedMosques.isEmpty
                            ? SizedBox(
                                key: const ValueKey('empty'),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.no_saved_mosques_found,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                key: const ValueKey('list'),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _savedMosques.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 16,
                                      color: Colors.transparent,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = _savedMosques[index];
                                  final isSelected = _selectedItemsList.any(
                                    (m) => m.id == item.id,
                                  );

                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    color: isSelected
                                        ? const Color(0xFFE8F4FA)
                                        : Colors.white,
                                    elevation: isSelected ? 5 : 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.buttonBlue
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => _toggleSelection(item),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item.image != null &&
                                              item.image!.isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: item.image!,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    height: 140,
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child:
                                                          WaterLoadingIndicator(
                                                            size: 30,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        height: 140,
                                                        color: Colors.grey[100],
                                                        child: Icon(
                                                          Icons.mosque,
                                                          size: 40,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      ),
                                            )
                                          else
                                            Container(
                                              height: 140,
                                              color: Colors.grey[100],
                                              child: Icon(
                                                Icons.mosque,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.localizedName(
                                                          isAr,
                                                        ),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (item
                                                          .address
                                                          .isNotEmpty)
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .location_on_outlined,
                                                              color:
                                                                  Colors.black,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                item.address,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey[600],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                // Heart icon: removes from favorites
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.favorite,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () =>
                                                      _removeFavorite(item),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedItemsList.isNotEmpty) _buildBottomBar(isAr),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
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
                        onTap: () => _toggleSelection(item),
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
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continue_btn,
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
}
