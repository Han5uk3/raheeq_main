import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/product_selection_page.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';

class SelectProductsScreen extends StatefulWidget {
  final List<SelectedCategoryItem> selectedCategories;
  final List<Product> availableProducts;

  const SelectProductsScreen({
    super.key,
    required this.selectedCategories,
    required this.availableProducts,
  });

  @override
  State<SelectProductsScreen> createState() => _SelectProductsScreenState();
}

class _SelectProductsScreenState extends State<SelectProductsScreen> {
  late List<OrderCategoryState> _orderStates;

  @override
  void initState() {
    super.initState();
    _orderStates = widget.selectedCategories
        .map((c) => OrderCategoryState(categoryItem: c))
        .toList();
  }

  bool get _isContinueEnabled {
    // Enabled if all categories have at least one product selected
    return _orderStates.every((state) => state.selectedProducts.isNotEmpty);
  }

  void _navigateToProductSelection(OrderCategoryState state, int index) async {
    final updatedState = await Navigator.of(context).push<OrderCategoryState>(
      MaterialPageRoute(
        builder: (_) => ProductSelectionPage(
          orderState: state,
          availableProducts: widget.availableProducts,
        ),
      ),
    );

    if (updatedState != null) {
      setState(() {
        _orderStates[index] = updatedState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'تحديد المنتجات' : 'Select Products';
    final subtitle = isAr
        ? 'اختر المنتجات لكل فئة'
        : 'Choose products for each category';

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
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _orderStates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final state = _orderStates[index];
                          final category = state.categoryItem.category;
                          final hasProducts = state.selectedProducts.isNotEmpty;

                          String locationText = "";
                          final slug = category.slug;
                          final optionType = state.categoryItem.optionType;
                          String categoryLabel = category.localizedLabel(isAr);
                          if (slug == 'specific_mosque') {
                            categoryLabel = isAr
                                ? 'مسجد محدد'
                                : 'Specific Mosque';
                          }

                          if (optionType == 'specific') {
                            locationText =
                                state.categoryItem.specificData?.localizedName(
                                  isAr,
                                ) ??
                                "";
                          } else if (optionType == 'most_in_need') {
                            if (slug == 'orphanages') {
                              locationText = isAr
                                  ? 'دار أيتام الأشد حاجة'
                                  : 'Most needy orphanage';
                            } else if (slug == 'meqat_mosques') {
                              locationText = isAr
                                  ? 'مسجد ميقات الأشد حاجة'
                                  : 'Most needy meqat mosque';
                            } else if (slug == 'mosques_in_need') {
                              final city =
                                  state.categoryItem.specificData as String?;
                              locationText =
                                  (isAr
                                      ? 'الأشد حاجة في '
                                      : 'Most in need in ') +
                                  (city ?? '');
                            } else {
                              locationText = isAr
                                  ? 'الأشد حاجة'
                                  : 'Most in need';
                            }
                          } else if (slug == 'remote_mosques' ||
                              slug == 'cemeteries') {
                            locationText = "";
                          } else {
                            locationText = isAr ? "غير محدد" : "General";
                          }

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: hasProducts
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  _navigateToProductSelection(state, index),
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
                                      child: category.image.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                category.image,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.category,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            categoryLabel,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (locationText.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              locationText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (hasProducts)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                isAr
                                                    ? "تم اختيار ${state.selectedProducts.length} منتجات"
                                                    : "${state.selectedProducts.length} products selected",
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                          onPressed: _isContinueEnabled
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReviewOrderPage(
                                        orderStates: _orderStates,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlueDark,
                            disabledBackgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            isAr ? 'متابعة' : 'Continue',
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
          ),
        ],
      ),
    );
  }
}
