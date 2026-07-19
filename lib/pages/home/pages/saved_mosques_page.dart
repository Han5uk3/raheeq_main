import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/mosque.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/pages/home/widgets/mosque_card.dart';

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
        if (e.toString().contains('connection error')) {
          _errorMessage = AppLocalizations.of(context)!.internet_error;
        } else {
          _errorMessage = e.toString();
        }
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
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark,
                      border: Border.all(
                        color: AppColors.buttonBlueDark,
                        width: 0,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        border: Border.all(style: BorderStyle.none, width: 0),
                      ),
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
                            : _errorMessage != null
                            ? Container(
                                key: const ValueKey('error'),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
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
                                        _errorMessage ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _fetchSavedMosques,
                                        icon: const Icon(Icons.refresh),
                                        label: Text(
                                          AppLocalizations.of(context)!.retry,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.buttonBlueDark,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                  return mosqueCard(
                                    isFromSavedMosques: true,
                                    isSelected: isSelected,
                                    item: item,
                                    slug: _mosquesCategory.slug,
                                    onTapCard: () => _toggleSelection(item),
                                    context: context,
                                    isAr: isAr,
                                    isHighNeed: false,
                                    toggleFavorite: () => _removeFavorite(item),
                                    favoriteMosqueIds: _savedMosques
                                        .map((e) => e.id)
                                        .toList(),
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
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.buttonBlueDark),
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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.transparent, width: 1.5),
            ),
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.all(12),
                  child: Container(
                    height: 73,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                          Container(
                            height: 16,
                            width: 120,
                            color: Colors.white,
                          ),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Container(height: 12, width: 60, color: Colors.white),
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
    );
  }
}
