import 'package:raheeq_main/l10n/app_localizations.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/models/campaign.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/donation_type_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_plans_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_details_bottom_sheet.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CampaignDetailPage extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailPage({super.key, required this.campaign});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  Product? _selectedProduct;
  Map<String, int> _selectedQuantities = {};
  Map<String, bool> _isCustomMap = {};
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  Map<String, String> _productNotes = {};
  Map<String, bool> _isNoteRevealed = {};
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  bool get _hasAnySelection => _selectedQuantities.values.any((qty) => qty > 0);

  @override
  void initState() {
    super.initState();

    // Auto-select first product if available
    if (widget.campaign.products.isNotEmpty) {
      _selectedProduct = widget.campaign.products.first;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _customFocusNode.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  double get _totalAmount {
    double total = 0;
    for (var product in widget.campaign.products) {
      final qty = _selectedQuantities[product.id];
      if (qty != null && qty > 0) {
        total += ((product.price) * qty) + product.deliveryFee;
      }
    }
    return total;
  }

  void _selectProduct(Product product) {
    if (_selectedProduct?.id == product.id) return;
    setState(() {
      _selectedProduct = product;
      _customFocusNode.unfocus();
      _noteFocusNode.unfocus();
      if (_isCustomMap[product.id] == true) {
        _customController.text =
            _selectedQuantities[product.id]?.toString() ?? '';
      } else {
        _customController.clear();
      }
      if (_isNoteRevealed[product.id] == true) {
        _noteController.text = _productNotes[product.id] ?? '';
      } else {
        _noteController.clear();
      }
    });
  }

  void _selectQuantity(int quantity) {
    setState(() {
      if (_selectedQuantities[_selectedProduct!.id] == quantity &&
          _isCustomMap[_selectedProduct!.id] != true) {
        _selectedQuantities.remove(_selectedProduct!.id);
      } else {
        _selectedQuantities[_selectedProduct!.id] = quantity;
        _isCustomMap[_selectedProduct!.id] = false;
        _customFocusNode.unfocus();
        _customController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.campaign.localizedTitle(isAr);
    final description = widget.campaign.localizedDescription(isAr);
    final products = widget.campaign.products;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildFloatingBar(context, isAr),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
          ),

          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAppBar(
                  title: title,
                  subtitle: description,
                  isStartAligned: true,
                  showBackButton: true,
                  hasBackgroundColor: true,
                ),

                // Stack for List and Quantity Container to create floating effect
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Quantity Selection Container (Background in Stack)
                    Container(
                      margin: const EdgeInsets.only(
                        top: 100,
                      ), // Start lower so list overlaps it
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 300,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 55,
                            ), // Space for overlapping Horizontal Product List
                            _buildCampaignBanner(_selectedProduct),

                            Container(
                              width: double.infinity,
                              margin: const EdgeInsetsDirectional.only(
                                top: 16,
                                start: 16,
                                end: 16,
                              ),
                              padding: EdgeInsetsDirectional.only(
                                start: 12,
                                end: 12,
                                top: 12,
                                bottom: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.buttonBlueDark,
                                border: Border.all(
                                  color: AppColors.buttonBlueDark,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.discount_outlined,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.priceIncludesDistributionDeliveryAndDocumentation,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 12,
                                end: 12,
                                top: 12, // spacing after banner
                                bottom:
                                    280, // extra space for bottom bar and keyboard
                              ),
                              child: _selectedProduct != null
                                  ? _buildQuantitySection(context, isAr)
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 50,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.select_a_product_to_continue,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Horizontal Product List inside a white container (Foreground in Stack)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;

                          int visibleCount = products.length;
                          if (visibleCount == 0) visibleCount = 1;
                          if (visibleCount > 3) visibleCount = 3;

                          final spacing = 12.0 * (visibleCount - 1);
                          final totalTakenSpace =
                              32.0 +
                              24.0 +
                              spacing; // Container margin (16*2) + ListView padding (12*2) + Spacing
                          final itemWidth =
                              (screenWidth - totalTakenSpace) / visibleCount;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                height: 130,
                                child: ListView.separated(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: products.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(
                                      products[index],
                                      isAr,
                                      itemWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignBanner(Product? product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 420 / 235,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              product?.serialNumber == 3
                  ? "assets/campaign/meals_banner.jpg"
                  : product?.serialNumber == 5
                  ? "assets/campaign/umbrellas_banner.jpg"
                  : "assets/campaign/cold_water_bottle_banner.jpg",
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isAr, double width) {
    final isSelected = _selectedProduct?.id == product.id;
    final name = product.localizedName(isAr);

    return GestureDetector(
      onTap: () => _selectProduct(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2381A6) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              product.serialNumber == 3
                  ? Icons.restaurant_outlined
                  : product.serialNumber == 5
                  ? Icons.beach_access_outlined
                  : Icons.water_drop_outlined,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, bool isAr) {
    final product = _selectedProduct!;
    final presets = product.presetQuantities.toList()..sort();
    final min = product.minQuantity;

    String itemName(int qty) {
      final isPlural = qty > 1;
      if (product.serialNumber == 3) {
        return isPlural
            ? AppLocalizations.of(context)!.meals
            : AppLocalizations.of(context)!.meal;
      } else if (product.serialNumber == 5) {
        return isPlural
            ? AppLocalizations.of(context)!.umbrellas
            : AppLocalizations.of(context)!.umbrella;
      }
      return isPlural
          ? AppLocalizations.of(context)!.bottles
          : AppLocalizations.of(context)!.bottle;
    }

    return Card(
      elevation: 10,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF2381A6)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.select_your_impact,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102840),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            GridView.builder(
              padding: EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final qty = presets[index];
                final price = (qty * (product.price)) + product.deliveryFee;
                return GestureDetector(
                  onTap: () => _selectQuantity(qty),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          _selectedQuantities[product.id] == qty &&
                              _isCustomMap[product.id] != true
                          ? const Color(0xFF2381A6).withValues(alpha: 0.1)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _selectedQuantities[product.id] == qty &&
                                _isCustomMap[product.id] != true
                            ? const Color(0xFF2381A6)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsetsDirectional.only(start: 8, end: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$qty ${itemName(qty)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "\u202A${AppLocalizations.of(context)!.sar_currency} ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}\u202C",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.or_enter_custom_quantity_min_min
                  .replaceAll(r'$min', min.toString()),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey, width: 1.5),
              ),
              child: TextField(
                scrollPadding: const EdgeInsets.only(bottom: 200),
                cursorColor: AppColors.buttonBlueDark,
                controller: _customController,
                focusNode: _customFocusNode,

                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTap: () {
                  setState(() {
                    _isCustomMap[product.id] = true;
                    _selectedQuantities.remove(product.id);
                  });
                },
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= min) {
                    setState(() {
                      _selectedQuantities[product.id] = parsed;
                    });
                  } else {
                    setState(() {
                      _selectedQuantities.remove(product.id);
                    });
                  }
                },
                decoration: InputDecoration(
                  suffixText: itemName(2),
                  suffixStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: AppLocalizations.of(context)!.enter_quantity,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isNoteRevealed[product.id] != true)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isNoteRevealed[product.id] = true;
                    _noteController.text = _productNotes[product.id] ?? '';
                  });
                },
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.add_note),
                style: TextButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2381A6),
                ),
              )
            else
              Container(
                padding: const EdgeInsetsDirectional.only(
                  bottom: 16,
                  end: 16,
                  start: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.transparent, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.note_prefix} ${product.localizedName(isAr)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsets.zero),
                          ),
                          onPressed: () {
                            setState(() {
                              _isNoteRevealed[product.id] = false;
                              _noteController.clear();
                              _productNotes.remove(product.id);
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey, width: 1.5),
                      ),
                      child: TextField(
                        scrollPadding: const EdgeInsets.only(bottom: 200),
                        cursorColor: Colors.grey,
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        maxLines: 3,
                        onChanged: (val) {
                          _productNotes[product.id] = val;
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context, bool isAr) {
    final total = _totalAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.buttonBlue,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.payable_amount,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "\u202A${AppLocalizations.of(context)!.sar_currency} ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}\u202C",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              if (_hasAnySelection) {
                if (widget.campaign.canSubscribe) {
                  _showDonationTypeDialog(context, isAr);
                } else {
                  _processOneTimeCheckout(context, isAr);
                }
              } else {
                final min = _selectedProduct?.minQuantity ?? 1;
                final customText = _customController.text;
                final parsed = int.tryParse(customText);

                if (_isCustomMap[_selectedProduct?.id] == true &&
                    customText.isNotEmpty &&
                    parsed != null &&
                    parsed < min) {
                  CustomSnackbar.show(
                    context: context,
                    message: AppLocalizations.of(
                      context,
                    )!.minimum_quantity_is(min.toString()),
                    isError: true,
                  );
                } else {
                  CustomSnackbar.show(
                    context: context,
                    message: AppLocalizations.of(
                      context,
                    )!.select_a_product_to_continue,
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.continue_btn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _prepareCheckoutItems() {
    final List<Map<String, dynamic>> items = [];
    _selectedQuantities.forEach((productId, qty) {
      if (qty > 0) {
        final note = _productNotes[productId];
        final item = <String, dynamic>{'productId': productId, 'quantity': qty};
        if (note != null && note.trim().isNotEmpty) {
          item['note'] = note.trim();
        }
        items.add(item);
      }
    });
    return items;
  }

  void _showDonationTypeDialog(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DonationTypeBottomSheet(
        onOneTimeSelected: () => _processOneTimeCheckout(context, isAr),
        onMonthlySelected: () =>
            _showSubscriptionPlansBottomSheet(context, isAr),
      ),
    );
  }

  void _showSubscriptionPlansBottomSheet(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionPlansBottomSheet(
        onPlanSelected: (plan) {
          _showSubscriptionDetailsBottomSheet(context, plan, isAr);
        },
        onBack: () {
          _showDonationTypeDialog(context, isAr);
        },
      ),
    );
  }

  void _showSubscriptionDetailsBottomSheet(
    BuildContext context,
    SubscriptionPlan plan,
    bool isAr,
  ) {
    final items = _prepareCheckoutItems();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionDetailsBottomSheet(
        plan: plan,
        checkoutItems: items,
        orderStates: const [],
        campaignId: widget.campaign.id,
        onBack: () {
          _showSubscriptionPlansBottomSheet(context, isAr);
        },
      ),
    );
  }

  Future<void> _processOneTimeCheckout(BuildContext context, bool isAr) async {
    final items = _prepareCheckoutItems();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingCtx) {
        return const Center(child: WaterLoadingIndicator());
      },
    );

    try {
      final apiService = ApiService();
      final response = await apiService.createCheckoutCampaign(
        campaignId: widget.campaign.id,
        items: items,
      );
      log('createCheckoutCampaign response: ${response.data}');

      final checkoutDataMap = response.data['data'];
      final checkoutData = Checkout.fromJson(checkoutDataMap);

      Navigator.pop(context); // Close loading dialog

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributionDetailsPage(
              orderStates: const [], // Empty for campaigns
              donationType: AppLocalizations.of(context)!.one_time_donation,
              checkoutData: checkoutData,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      log('Error creating checkout: $e', error: e);
      if (mounted) {
        String errorMessage = AppLocalizations.of(
          context,
        )!.error_occurred_try_again;
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          bottomMargin: 130,
          isError: true,
        );
      }
    }
  }
}
