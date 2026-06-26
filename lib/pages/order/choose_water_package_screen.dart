import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';

// A lightweight model to represent one "slot" in the horizontal list
class _ProductSlot {
  final Product product;
  final bool isChiller;
  final int quantity; // 1 for chiller, preset qty for cartons

  const _ProductSlot({
    required this.product,
    required this.isChiller,
    required this.quantity,
  });

  String get id => '${product.id}_$quantity';
}

class ChooseWaterPackageScreen extends StatefulWidget {
  final List<SelectedCategoryItem> selectedCategories;
  final List<Product> availableProducts;

  const ChooseWaterPackageScreen({
    super.key,
    required this.selectedCategories,
    required this.availableProducts,
  });

  @override
  State<ChooseWaterPackageScreen> createState() =>
      _ChooseWaterPackageScreenState();

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required List<SelectedCategoryItem> selectedCategories,
    required List<Product> availableProducts,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => ChooseWaterPackageScreen(
        selectedCategories: selectedCategories,
        availableProducts: availableProducts,
      ),
    );
  }
}

class _ChooseWaterPackageScreenState extends State<ChooseWaterPackageScreen> {
  // Selected slot IDs
  String? _selectedChillerSlotId;
  String? _selectedCartonSlotId;

  // ── Build the flat list of slots ────────────────────────────────────────────

  List<_ProductSlot> get _slots {
    final slots = <_ProductSlot>[];

    // 1. Chiller first (always one card)
    final chiller = widget.availableProducts
        .where((p) => p.serialNumber == 2)
        .firstOrNull;
    if (chiller != null) {
      slots.add(_ProductSlot(product: chiller, isChiller: true, quantity: 1));
    }

    // 2. One card per preset quantity for every carton product
    final cartons = widget.availableProducts.where(
      (p) => p.serialNumber == 1 || p.serialNumber == 4,
    );

    for (final carton in cartons) {
      final quantities = carton.validQuantities; // already sorted, min first
      for (final qty in quantities) {
        slots.add(
          _ProductSlot(product: carton, isChiller: false, quantity: qty),
        );
      }
    }

    return slots;
  }

  // ── Selection helpers ────────────────────────────────────────────────────────

  bool _isSlotSelected(_ProductSlot slot) {
    return slot.isChiller
        ? _selectedChillerSlotId == slot.id
        : _selectedCartonSlotId == slot.id;
  }

  void _toggleSlot(_ProductSlot slot) {
    setState(() {
      if (slot.isChiller) {
        _selectedChillerSlotId = _selectedChillerSlotId == slot.id
            ? null
            : slot.id;
      } else {
        // Tapping the already-selected carton deselects it
        _selectedCartonSlotId = _selectedCartonSlotId == slot.id
            ? null
            : slot.id;
      }
    });
  }

  bool get _isContinueEnabled =>
      _selectedChillerSlotId != null || _selectedCartonSlotId != null;

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _navigateToReview() {
    if (!_isContinueEnabled) return;

    final allSlots = _slots;
    final List<SelectedProduct> selectedProducts = [];

    if (_selectedChillerSlotId != null) {
      final selectedChiller = allSlots.firstWhere(
        (s) => s.id == _selectedChillerSlotId,
      );
      selectedProducts.add(
        SelectedProduct(product: selectedChiller.product, quantity: 1),
      );
    }

    if (_selectedCartonSlotId != null) {
      final selectedCarton = allSlots.firstWhere(
        (s) => s.id == _selectedCartonSlotId,
      );
      selectedProducts.add(
        SelectedProduct(
          product: selectedCarton.product,
          quantity: selectedCarton.quantity,
        ),
      );
    }

    final List<OrderCategoryState> orderStates = widget.selectedCategories.map((
      categoryItem,
    ) {
      return OrderCategoryState(
        categoryItem: categoryItem,
        selectedProducts: selectedProducts
            .map(
              (sp) => SelectedProduct(
                product: sp.product,
                quantity: sp.quantity,
                notes: sp.notes,
              ),
            )
            .toList(),
      );
    }).toList();

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewOrderPage(orderStates: orderStates),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.choose_water_package;
    final subtitle = AppLocalizations.of(context)!.choose_water_package_desc;

    final slots = _slots;

    return Container(
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
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Container(
              width: 70,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal slot list
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final isSelected = _isSlotSelected(slot);

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16.0 : 2.0,
                    right: index == slots.length - 1 ? 16.0 : 2.0,
                  ),
                  child: _buildSlotCard(
                    slot: slot,
                    isSelected: isSelected,
                    onTap: () => _toggleSlot(slot),
                    isAr: isAr,
                  ),
                );
              },
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isContinueEnabled ? _navigateToReview : null,
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

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSlotCard({
    required _ProductSlot slot,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAr,
  }) {
    final product = slot.product;
    final unitPrice = product.price;
    final totalPrice = unitPrice * slot.quantity;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 125,
        height: 200,
        child: Card(
          color: Colors.white,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? AppColors.buttonBlue : Colors.transparent,
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
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              height: 20,
                              child: WaterLoadingIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.water_drop,
                              color: AppColors.buttonBlue,
                              size: 40,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.water_drop,
                            color: AppColors.buttonBlue,
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
                        slot.isChiller
                            ? AppLocalizations.of(context)!.two_year_guarantee
                            : (isAr ? product.subtitleAr : product.subtitle),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Product name
                      Text(
                        "${slot.quantity} ${product.localizedName(isAr)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Price
                      Text(
                        '\u202A${AppLocalizations.of(context)!.sar_currency} ${totalPrice.toStringAsFixed(0)}\u202C',
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
      ),
    );
  }
}
