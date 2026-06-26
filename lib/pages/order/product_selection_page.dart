import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class ProductSelectionPage extends StatefulWidget {
  final OrderCategoryState orderState;
  final List<Product> availableProducts;

  const ProductSelectionPage({
    super.key,
    required this.orderState,
    required this.availableProducts,
  });

  @override
  State<ProductSelectionPage> createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  // Map of productId to SelectedProduct
  late Map<String, SelectedProduct> _selections;

  @override
  void initState() {
    super.initState();
    _selections = {};
    for (var sp in widget.orderState.selectedProducts) {
      _selections[sp.product.id] = SelectedProduct(
        product: sp.product,
        quantity: sp.quantity,
        notes: sp.notes,
      );
    }
  }

  void _updateQuantity(Product product, int qty) {
    setState(() {
      if (qty <= 0) {
        _selections.remove(product.id);
      } else {
        if (_selections.containsKey(product.id)) {
          _selections[product.id]!.quantity = qty;
        } else {
          _selections[product.id] = SelectedProduct(
            product: product,
            quantity: qty,
          );
        }
      }
    });
  }

  void _updateNotes(Product product, String notes) {
    if (_selections.containsKey(product.id)) {
      _selections[product.id]!.notes = notes;
    }
  }

  void _saveAndReturn() {
    final updatedState = OrderCategoryState(
      categoryItem: widget.orderState.categoryItem,
      selectedProducts: _selections.values.toList(),
    );
    Navigator.of(context).pop(updatedState);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.orderState.categoryItem.category.localizedLabel(isAr);
    final subtitle = AppLocalizations.of(context)!.select_quantities_and_notes;

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
            child: Container(
              color: const Color(0x4D91E3FE),

              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: widget.availableProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = widget.availableProducts[index];
                        final selection = _selections[product.id];
                        final currentQty = selection?.quantity ?? 0;

                        return _buildProductCard(
                          product,
                          currentQty,
                          selection?.notes ?? '',
                          isAr,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveAndReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.save_return,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    int currentQty,
    String notes,
    bool isAr,
  ) {
    final quantities = product.validQuantities;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: currentQty > 0 ? AppColors.buttonBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(product.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.localizedName(isAr),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.formattedPrice(
                          AppLocalizations.of(context)!.sar_per_unit,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.buttonBlueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.quantity,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final qty in quantities)
                  ChoiceChip(
                    label: Text('$qty'),
                    selected: currentQty == qty,
                    onSelected: (selected) {
                      if (selected) {
                        _updateQuantity(product, qty);
                      } else if (currentQty == qty) {
                        _updateQuantity(product, 0);
                      }
                    },
                    selectedColor: AppColors.buttonBlue,
                    labelStyle: TextStyle(
                      color: currentQty == qty ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                // Custom Amount Input Trigger
                ActionChip(
                  label: Text(AppLocalizations.of(context)!.custom),
                  onPressed: () =>
                      _showCustomQuantityDialog(product, currentQty, isAr),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            if (currentQty > 0) ...[
              const SizedBox(height: 16),
              TextField(
                cursorColor: AppColors.buttonBlueDark,

                controller: TextEditingController(text: notes)
                  ..selection = TextSelection.collapsed(offset: notes.length),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notes_optional,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) => _updateNotes(product, val),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCustomQuantityDialog(Product product, int currentQty, bool isAr) {
    final controller = TextEditingController(
      text: currentQty > 0 ? currentQty.toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enter_quantity_204),
          content: TextField(
            cursorColor: AppColors.buttonBlueDark,

            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.example_quantity,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val >= product.minQuantity) {
                  _updateQuantity(product, val);
                }
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        );
      },
    );
  }
}
