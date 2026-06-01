import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/models/city.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'dart:developer';
import 'package:raheeq_main/pages/order/subscription_plan_selection_page.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class ReviewOrderPage extends StatefulWidget {
  final List<OrderCategoryState> orderStates;

  const ReviewOrderPage({super.key, required this.orderStates});

  @override
  State<ReviewOrderPage> createState() => _ReviewOrderPageState();
}

class _ReviewOrderPageState extends State<ReviewOrderPage> {
  late List<Product> _uniqueProducts;

  @override
  void initState() {
    super.initState();
    final productMap = <String, Product>{};
    for (final state in widget.orderStates) {
      for (final sp in state.selectedProducts) {
        productMap[sp.product.id] = sp.product;
      }
    }
    _uniqueProducts = productMap.values.toList();
  }

  double get _totalPrice {
    return widget.orderStates.fold(0, (sum, state) => sum + state.totalPrice);
  }

  int get _totalQuantity {
    return widget.orderStates.fold(0, (sum, state) {
      return sum +
          state.selectedProducts.fold(
            0,
            (productSum, sp) => productSum + sp.quantity,
          );
    });
  }

  void _showDonationTypeDialog(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedType = 'one_time';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'اختر نوع التبرع' : 'Choose Donation Type',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close, color: AppColors.black),
                        ),
                      ],
                    ),

                    Text(
                      isAr
                          ? 'ادعم مرة واحدة أو اصنع أثراً مستداماً'
                          : 'Support once or make a lasting impact',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDonationOption(
                            isAr: isAr,
                            title: isAr ? 'مرة واحدة' : 'One-Time',
                            subtitle: isAr
                                ? 'تبرع لمرة واحدة'
                                : 'Single donation',
                            icon: Icons.calendar_today_outlined,
                            isSelected: selectedType == 'one_time',
                            onTap: () {
                              setState(() {
                                selectedType = 'one_time';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDonationOption(
                            isAr: isAr,
                            title: isAr ? 'شهري' : 'Subscription',
                            subtitle: isAr ? 'أثر مستدام' : 'Recurring impact',
                            icon: Icons.sync,
                            isSelected: selectedType == 'monthly',
                            onTap: () {
                              setState(() {
                                selectedType = 'monthly';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            _processCheckout(context, selectedType, ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF196482,
                          ), // Darker blue for continue button
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _prepareCheckoutItems() {
    final List<Map<String, dynamic>> items = [];
    for (final state in widget.orderStates) {
      final category = state.categoryItem.category;
      for (final sp in state.selectedProducts) {
        final item = <String, dynamic>{
          'productId': sp.product.id,
          'quantity': sp.quantity,
        };
        if (sp.notes != null && sp.notes!.trim().isNotEmpty) {
          item['note'] = sp.notes!.trim();
        }
        final optionType = state.categoryItem.optionType;
        final slug = category.slug;
        if (optionType == 'specific') {
          final specificData = state.categoryItem.specificData;
          if (specificData is Place) {
            item['locationId'] = specificData.id;
          } else if (specificData is City) {
            item['cityId'] = specificData.id;
          }
        } else {
          item['categorySlug'] = slug;
        }
        items.add(item);
      }
    }
    return items;
  }

  Future<void> _processCheckout(
    BuildContext context,
    String selectedType, [
    BuildContext? dialogCtx,
  ]) async {
    final localIsAr = Localizations.localeOf(context).languageCode == 'ar';
    final items = _prepareCheckoutItems();

    if (selectedType == 'monthly') {
      if (dialogCtx != null) {
        Navigator.pop(dialogCtx);
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubscriptionPlanSelectionPage(
            checkoutItems: items,
            orderStates: widget.orderStates,
          ),
        ),
      );
      return;
    }

    showDialog(
      context: dialogCtx ?? context,
      barrierDismissible: false,
      builder: (BuildContext loadingCtx) {
        return const Center(child: WaterLoadingIndicator());
      },
    );

    try {
      final apiService = ApiService();
      final isEssential = widget.orderStates.any(
        (state) => state.categoryItem.category.slug == 'essential_supplies',
      );
      final response = isEssential
          ? await apiService.createCheckoutEssential(items: items)
          : await apiService.createCheckoutQuick(items: items);
      log('createCheckout response: ${response.data}');

      final checkoutDataMap = response.data['data'];
      final checkoutData = Checkout.fromJson(checkoutDataMap);

      Navigator.pop(dialogCtx ?? context); // Close loading dialog
      if (dialogCtx != null) {
        Navigator.pop(dialogCtx); // Close donation type dialog
      }

      if (mounted) {
        _navigateToDetails(
          context,
          localIsAr
              ? (selectedType == 'one_time'
                    ? 'تبرع لمرة واحدة'
                    : 'تبرع شهري متكرر')
              : (selectedType == 'one_time'
                    ? 'One-time Donation'
                    : 'Recurring Donation'),
          checkoutData: checkoutData,
        );
      }
    } catch (e) {
      Navigator.pop(dialogCtx ?? context); // Close loading dialog
      log('Error creating checkout: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localIsAr
                  ? 'حدث خطأ. حاول مرة أخرى'
                  : 'Error occurred. Try again',
            ),
          ),
        );
      }
    }
  }

  Widget _buildDonationOption({
    required bool isAr,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF389BB8)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF389BB8),
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.buttonBlueDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -8,
              right: isAr ? null : -8,
              left: isAr ? -8 : null,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF389BB8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetails(
    BuildContext context,
    String donationType, {
    required Checkout checkoutData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContributionDetailsPage(
          orderStates: widget.orderStates,
          donationType: donationType,
          checkoutData: checkoutData,
        ),
      ),
    );
  }

  Widget _buildProductTab(Product product, bool isAr) {
    // find all category states that contain this product
    final relevantStates = widget.orderStates.where((state) {
      return state.selectedProducts.any((sp) => sp.product.id == product.id);
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      itemCount: relevantStates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final state = relevantStates[index];
        final category = state.categoryItem.category;
        final sp = state.selectedProducts.firstWhere(
          (p) => p.product.id == product.id,
        );

        final slug = category.slug;
        final optionType = state.categoryItem.optionType;
        String originalCategoryLabel = category.localizedLabel(isAr);
        String categoryLabel = originalCategoryLabel;
        String locationText = "";

        if (optionType == 'specific') {
          final specificData = state.categoryItem.specificData;
          if (specificData is Place) {
            categoryLabel = specificData.localizedName(isAr);
            locationText = specificData.address;
          } else {
            categoryLabel = specificData?.localizedName(isAr) ?? "";
            locationText = "";
          }
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
            final specificData = state.categoryItem.specificData;
            if (specificData != null) {
              // Can be a City object or a String depending on where it was selected
              if (specificData is City) {
                categoryLabel = specificData.localizedName(isAr);
              } else if (specificData is String) {
                categoryLabel = specificData;
              } else {
                try {
                  categoryLabel = specificData.localizedName(isAr);
                } catch (_) {}
              }
            }
            locationText = "";
          } else {
            locationText = isAr ? 'الأشد حاجة' : 'Most in need';
          }
        } else if (slug == 'remote_mosques' || slug == 'cemeteries') {
          locationText = "";
        } else {
          locationText = isAr ? "غير محدد" : "General";
        }

        // If the title of the card was changed to something specific (like a mosque name or city name),
        // show the original category name where the location would normally be shown.
        if (categoryLabel != originalCategoryLabel) {
          locationText = originalCategoryLabel;
        }

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          if (locationText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              locationText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: sp.quantity > sp.product.minQuantity
                                ? 1.0
                                : 0.45,
                            child: GestureDetector(
                              onTap: sp.quantity > sp.product.minQuantity
                                  ? () {
                                      setState(() {
                                        sp.quantity -= 1;
                                      });
                                    }
                                  : null,
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sp.quantity > sp.product.minQuantity
                                      ? Colors.white
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: sp.quantity > sp.product.minQuantity
                                      ? AppColors.buttonBlue
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${sp.quantity}x",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buttonBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                sp.quantity += 1;
                              });
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.buttonBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: sp.notes,
                  maxLines: 3,
                  onChanged: (val) {
                    sp.notes = val;
                  },
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'هل تود إضافة ملاحظة لمندوب التوصيل؟'
                        : 'Would you like to add a note to the delivery agent?',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.buttonBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'تفاصيل الطلب' : 'Order Details';
    final subtitle = isAr ? 'تحقق من تفاصيل طلبك' : 'Verify your order details';

    if (_uniqueProducts.isEmpty) {
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
            Expanded(child: Center(child: Text(AppLocalizations.of(context)!.no_products_selected))),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: _uniqueProducts.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: BottomActionPill(
            subtitleWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? '$_totalQuantity عنصر' // or choose pluralization if needed
                      : '$_totalQuantity items',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr ? 'الإجمالي' : 'Total Price',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            titleWidget: Text(
              isAr
                  ? '${_totalPrice.toStringAsFixed(2)} ر.س'
                  : 'SAR ${_totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            buttonText: isAr ? 'متابعة' : 'Continue',
            onButtonTap: () {
              final hasChiller = _uniqueProducts.any(
                (p) => p.slug.toLowerCase().contains('chiller'),
              );
              if (hasChiller) {
                _processCheckout(context, 'one_time');
              } else {
                _showDonationTypeDialog(context, isAr);
              }
            },
          ),
        ),
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
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TabBar(
                            splashFactory: NoSplash.splashFactory,
                            isScrollable: _uniqueProducts.length > 3,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.buttonBlueDark,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: AppColors.buttonBlueDark,
                            ),
                            labelPadding: EdgeInsets.zero,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            tabs: _uniqueProducts
                                .map(
                                  (p) => Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        p.localizedName(isAr),
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: TabBarView(
                  children: _uniqueProducts.map((product) {
                    return _buildProductTab(product, isAr);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
