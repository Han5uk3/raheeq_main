import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/city.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/specific_mosque_page.dart';
import 'package:raheeq_main/pages/home/widgets/city_selector_dialog.dart';
import 'package:raheeq_main/pages/home/widgets/option_selector_dialog.dart';
import 'package:raheeq_main/pages/home/widgets/quick_service_grid_card.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';

/// A place-picking step the sheet cannot run itself.
///
/// [SpecificMosquePage] hosts a GoogleMap, and an Android platform view
/// rendered while a modal bottom sheet is still mounted underneath stalls the
/// renderer hard enough to ANR the process. So the sheet closes and asks the
/// caller to run the picker, exactly as every other bottom sheet in the app
/// pops before it pushes. [OrderChillerSheet.start] reopens the sheet with the
/// selection carried across.
class _PlacePickerRequest {
  final Category category;
  final String label;

  const _PlacePickerRequest({required this.category, required this.label});

  String get slug => category.slug;
}

/// Why the sheet closed, and what it had selected at the time.
class _SheetOutcome {
  final List<SelectedCategoryItem> selection;

  /// The picker to run before reopening the sheet. `null` means Continue was
  /// pressed and the selection is final.
  final _PlacePickerRequest? placePicker;

  const _SheetOutcome({required this.selection, this.placePicker});
}

/// Beneficiary picker for "order a new chiller".
///
/// Shows the same giving-opportunity tiles as the Home tab and runs the same
/// selection flows (option dialog, specific place page, city picker). The one
/// difference is what happens on Continue: the water chiller is picked for the
/// user, so this goes straight to the order details page instead of stopping at
/// the water package sheet. Everything after that — checkout, payment — is the
/// regular flow.
///
/// Entry point is [start], which drives the sheet and the place picker as one
/// flow.
class OrderChillerSheet extends StatefulWidget {
  final List<SelectedCategoryItem> initialSelection;

  const OrderChillerSheet({super.key, this.initialSelection = const []});

  @override
  State<OrderChillerSheet> createState() => _OrderChillerSheetState();

  /// Runs the whole selection flow: show the sheet, step out to the place
  /// picker whenever it asks, reopen it with what has been picked so far, and
  /// on Continue go to the order details page with the chiller selected.
  ///
  /// Every step back mirrors the step forward: backing out of the place picker
  /// or the order details page reopens the sheet with the selection intact, so
  /// the only way out of the flow is dismissing the sheet itself (or placing
  /// the order, which unwinds the whole stack).
  static Future<void> start(BuildContext context) async {
    // The route the flow was started from. A completed payment pops back to
    // the root, taking this route with it — that is what tells the loop the
    // flow is over rather than merely stepped back out of.
    final startRoute = ModalRoute.of(context);
    var selection = <SelectedCategoryItem>[];

    while (true) {
      final outcome = await showModalBottomSheet<_SheetOutcome>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (_) => OrderChillerSheet(initialSelection: selection),
      );

      // Dismissed by the back button, the barrier or a drag down.
      if (outcome == null || !context.mounted) return;
      selection = outcome.selection;

      final request = outcome.placePicker;
      if (request == null) {
        // Nothing to fall back to if the order details page never opened; the
        // failure has already been reported.
        if (!await _openOrderDetails(context, selection)) return;
        if (!context.mounted || startRoute?.isActive != true) return;
        continue;
      }

      final places = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => SpecificMosquePage(
            isEssentialProduct: false,
            slug: request.slug,
            initialSelections: _selectedPlacesFor(selection, request.slug),
            title: request.label,
          ),
        ),
      );
      if (!context.mounted) return;

      // A back-out returns null and leaves the selection as it was.
      if (places is List<Place>) {
        selection = _withPlaces(selection, request.category, places);
      }
    }
  }

  static List<Place> _selectedPlacesFor(
    List<SelectedCategoryItem> selection,
    String slug,
  ) {
    return selection
        .where(
          (item) => item.category.slug == slug && item.specificData is Place,
        )
        .map((item) => item.specificData as Place)
        .toList();
  }

  /// [selection] with every entry for [category]'s slug replaced by [places].
  static List<SelectedCategoryItem> _withPlaces(
    List<SelectedCategoryItem> selection,
    Category category,
    List<Place> places,
  ) {
    final merged = selection
        .where((item) => item.category.slug != category.slug)
        .toList();

    for (final place in places) {
      final exists = merged.any(
        (item) =>
            item.optionType == 'specific' &&
            item.specificData is Place &&
            (item.specificData as Place).id == place.id,
      );
      if (!exists) {
        merged.add(
          SelectedCategoryItem(
            category: category,
            optionType: 'specific',
            specificData: place,
          ),
        );
      }
    }
    return merged;
  }

  /// The chiller product at its smallest offered quantity — the selection the
  /// water package sheet would otherwise have asked for.
  static SelectedProduct? _chillerSelection() {
    Product? chiller;
    for (final product in HomeTab.cachedProducts) {
      if (product.serialNumber == 2) {
        chiller = product;
        break;
      }
    }
    if (chiller == null) return null;

    final minQuantity = chiller.minQuantity;
    final quantities =
        chiller.presetQuantities.where((q) => q >= minQuantity).toList()..sort();
    return SelectedProduct(
      product: chiller,
      quantity: quantities.isNotEmpty ? quantities.first : minQuantity,
    );
  }

  /// Pushes the order details page and waits for it to be popped. Returns
  /// false when it could not be opened at all.
  static Future<bool> _openOrderDetails(
    BuildContext context,
    List<SelectedCategoryItem> selection,
  ) async {
    if (selection.isEmpty) return false;

    final chiller = _chillerSelection();
    if (chiller == null) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.error,
        isError: true,
      );
      return false;
    }

    // Each category carries its own SelectedProduct — quantity is mutable on
    // the order details page and must not be shared between rows.
    final orderStates = selection
        .map(
          (categoryItem) => OrderCategoryState(
            categoryItem: categoryItem,
            selectedProducts: [
              SelectedProduct(
                product: chiller.product,
                quantity: chiller.quantity,
              ),
            ],
          ),
        )
        .toList();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewOrderPage(orderStates: orderStates),
      ),
    );
    return true;
  }
}

class _OrderChillerSheetState extends State<OrderChillerSheet> {
  /// This sheet keeps its own basket — it is a standalone "order a chiller"
  /// flow and does not touch whatever the Home tab has selected.
  late final List<SelectedCategoryItem> _selectedItems = List.of(
    widget.initialSelection,
  );

  List<Category> get _categories => HomeTab.cachedCategories;

  bool get _isContinueEnabled => _selectedItems.isNotEmpty;

  void _close({_PlacePickerRequest? placePicker}) {
    Navigator.of(context).pop(
      _SheetOutcome(
        selection: List.of(_selectedItems),
        placePicker: placePicker,
      ),
    );
  }

  // ── Selection flow (mirrors the Home tab's quick services grid) ─────────────

  Future<void> _onCategoryTap(Category category, String label) async {
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
          initialOption: isSelected
              ? _selectedItems[existingIndex].optionType
              : null,
        ),
      );
      if (result == null || !mounted) return;

      if (result == 'clear') {
        setState(() {
          _selectedItems.removeWhere((item) => item.category.slug == slug);
        });
        return;
      }

      if (result == 'most_in_need') {
        setState(() {
          _selectedItems.removeWhere((item) => item.category.slug == slug);
          _selectedItems.add(
            SelectedCategoryItem(
              category: category,
              optionType: 'most_in_need',
            ),
          );
        });
        return;
      }

      if (result == 'specific') {
        _close(
          placePicker: _PlacePickerRequest(category: category, label: label),
        );
      }
      return;
    }

    if (slug == 'mosques_in_need') {
      final currentlySelected = _selectedItems
          .where(
            (item) => item.category.slug == slug && item.specificData is City,
          )
          .map((item) => item.specificData as City)
          .toList();

      final cities = await showDialog<List<City>>(
        context: context,
        builder: (_) => CitySelectorDialog(
          initialSelections: currentlySelected,
          allCities: HomeTab.cachedCities,
        ),
      );
      if (cities == null || !mounted) return;

      setState(() {
        _selectedItems.removeWhere((item) => item.category.slug == slug);
        for (final city in cities) {
          final exists = _selectedItems.any(
            (item) =>
                item.optionType == 'most_in_need' &&
                item.specificData is City &&
                (item.specificData as City).id == city.id,
          );
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
      return;
    }

    if (slug == 'specific_mosque') {
      _close(
        placePicker: _PlacePickerRequest(category: category, label: label),
      );
      return;
    }

    setState(() {
      _selectedItems.add(
        SelectedCategoryItem(category: category, optionType: 'none'),
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.order_new_chiller,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.choose_where_to_give_and_create_a_lasting_impact,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GridView.builder(
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
                  final label = category.localizedLabel(isAr);
                  final slug = category.slug;
                  final isSelected = _selectedItems.any(
                    (item) => item.category.id == category.id,
                  );

                  return GestureDetector(
                    onTap: () => _onCategoryTap(category, label),
                    child: buildQuickServiceGridCard(
                      context,
                      label,
                      category.image.trim(),
                      isSelected: isSelected,
                      requiresChoosing:
                          slug == 'orphanages' ||
                          slug == 'meqat_mosques' ||
                          slug == 'mosques_in_need' ||
                          slug == 'specific_mosque',
                      onClear: isSelected
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
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isContinueEnabled ? _close : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isContinueEnabled
                      ? AppColors.buttonBlueDark
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  AppLocalizations.of(context)!.continue_btn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
        ],
      ),
    );
  }
}
