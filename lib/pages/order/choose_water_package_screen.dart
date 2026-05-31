import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';

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
}

class _WaterPackageOption {
  final Product product;
  final int? quantity;
  final bool isCustom;

  _WaterPackageOption(this.product, this.quantity) : isCustom = false;
}

class _ChooseWaterPackageScreenState extends State<ChooseWaterPackageScreen> {
  final Map<String, int> _selections = {};

  List<Product> get _waterProducts {
    final products = widget.availableProducts
        .where(
          (p) =>
              p.slug.contains('water') ||
              p.slug.contains('chiller') ||
              p.slug.contains('bottle') ||
              p.slug.contains('carton'),
        )
        .toList();

    products.sort((a, b) {
      final aIsChiller = a.slug.contains('chiller');
      final bIsChiller = b.slug.contains('chiller');
      if (aIsChiller && !bIsChiller) return -1;
      if (!aIsChiller && bIsChiller) return 1;
      return 0;
    });

    return products;
  }

  bool get _isContinueEnabled {
    return _selections.values.any((qty) => qty > 0);
  }

  void _updateQuantity(Product product, int qty) {
    setState(() {
      if (qty <= 0) {
        _selections.remove(product.id);
      } else {
        _selections[product.id] = qty;
      }
    });
  }

  void _navigateToReview() {
    List<OrderCategoryState> orderStates = widget.selectedCategories.map((
      categoryItem,
    ) {
      // Create a fresh list of selected products for each category
      final List<SelectedProduct> categoryProducts = _selections.entries.map((
        entry,
      ) {
        final product = widget.availableProducts.firstWhere(
          (p) => p.id == entry.key,
        );
        return SelectedProduct(product: product, quantity: entry.value);
      }).toList();

      return OrderCategoryState(
        categoryItem: categoryItem,
        selectedProducts: categoryProducts,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewOrderPage(orderStates: orderStates),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'اختر باقة المياه' : 'Choose Water Package';
    final subtitle = isAr
        ? 'اختر عدد كراتين وبرادات المياه'
        : 'Select water cartons and chillers';

    final products = _waterProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isContinueEnabled
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: BottomActionPill(
                titleWidget: Text(
                  isAr
                      ? 'محدد: ${_selections.length} عناصر'
                      : 'Selected: ${_selections.length} items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                buttonText: isAr ? 'متابعة' : 'Continue',
                onButtonTap: _navigateToReview,
              ),
            )
          : null,
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
              child: Container(
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
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 100,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final currentQty = _selections[product.id] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.localizedName(isAr),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                                Text(
                                  product.localizedSubtitle(isAr),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.grey,
                                  ),
                                ),

                                const SizedBox(height: 12),
                                ...product.validQuantities.map((qty) {
                                  final option = _WaterPackageOption(
                                    product,
                                    qty,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: _buildOptionCard(
                                      option,
                                      currentQty,
                                      isAr,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    _WaterPackageOption option,
    int currentQty,
    bool isAr,
  ) {
    final product = option.product;
    final qty = option.quantity;
    final isCustom = option.isCustom;

    final bool isSelected = isCustom
        ? (currentQty > 0 && !product.validQuantities.contains(currentQty))
        : (currentQty == qty);

    final displayQty = isCustom && isSelected ? currentQty : (qty ?? 0);
    final totalPrice = displayQty > 0
        ? ((product.price + product.deliveryFee) * displayQty)
        : 0.0;

    String title;
    if (isCustom) {
      title = isAr
          ? 'كمية مخصصة (${product.localizedName(isAr)})'
          : 'Custom Quantity (${product.localizedName(isAr)})';
      if (isSelected) {
        title = '$currentQty ${product.localizedName(isAr)}';
      }
    } else {
      title = '$qty ${product.localizedName(isAr)}';
    }

    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomQuantityDialog(product, currentQty, isAr);
        } else {
          if (isSelected) {
            _updateQuantity(product, 0);
          } else {
            _updateQuantity(product, qty!);
          }
        }
      },
      child: Card(
        color: Colors.white,
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.buttonBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.image.isNotEmpty
                      ? Image.network(product.image, fit: BoxFit.cover)
                      : const Icon(
                          Icons.water_drop,
                          color: AppColors.buttonBlue,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCustom || isSelected) ...[
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? '${totalPrice.toStringAsFixed(2)} ر.س'
                            : '${totalPrice.toStringAsFixed(2)} SAR',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.buttonBlueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.buttonBlue)
              else if (isCustom)
                const Icon(Icons.edit, color: Colors.grey, size: 20)
              else
                const Icon(Icons.circle_outlined, color: Colors.grey),
            ],
          ),
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
          title: Text(isAr ? 'أدخل الكمية' : 'Enter Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g., 50'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val >= product.minQuantity) {
                  _updateQuantity(product, val);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                foregroundColor: Colors.white,
              ),
              child: Text(isAr ? 'تأكيد' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }
}
