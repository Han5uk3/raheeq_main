import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/models/campaign.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/pages/order/subscription_plan_selection_page.dart';

class CampaignDetailPage extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailPage({super.key, required this.campaign});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage>
    with SingleTickerProviderStateMixin {
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

  void _updateBarAnimation() {
    if (_hasAnySelection) {
      if (_barAnimController.status != AnimationStatus.forward &&
          _barAnimController.status != AnimationStatus.completed) {
        _barAnimController.forward();
      }
    } else {
      if (_barAnimController.status != AnimationStatus.reverse &&
          _barAnimController.status != AnimationStatus.dismissed) {
        _barAnimController.reverse();
      }
    }
  }

  late AnimationController _barAnimController;
  late Animation<double> _barSlideAnimation;
  late Animation<double> _barFadeAnimation;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _barSlideAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _barFadeAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Auto-select first product if available
    if (widget.campaign.products.isNotEmpty) {
      _selectedProduct = widget.campaign.products.first;
    }
  }

  @override
  void dispose() {
    _barAnimController.dispose();
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
        total += (product.price + product.deliveryFee) * qty;
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
    _updateBarAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.campaign.localizedTitle(isAr);
    final description = widget.campaign.localizedDescription(isAr);
    final products = widget.campaign.products;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(decoration: const BoxDecoration(color: Color(0x4D91E3FE))),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(
                title: title,
                subtitle: description,
                isStartAligned: true,
                showBackButton: true,
                hasBackgroundColor: false,
              ),

              // Stack for List and Quantity Container to create floating effect
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Quantity Selection Container (Background in Stack)
                    Positioned(
                      top: 100, // Start lower so list overlaps it
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 85, // 80 overlap + 24 extra space
                              bottom: 120, // space for bottom bar
                            ),
                            child: _selectedProduct != null
                                ? _buildQuantitySection(context, isAr)
                                : Center(
                                    child: Text(
                                      isAr
                                          ? 'اختر منتجاً للمتابعة'
                                          : 'Select a product to continue',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
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
                          // Container margin: 16*2 = 32
                          // ListView padding: 12*2 = 24
                          // Spacing for 3 items: 12*2 = 24
                          // Total taken space without items: 80
                          final itemWidth = (screenWidth - 80) / 3;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            height: 160,
                            child: ListView.separated(
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Bottom Bar
          AnimatedBuilder(
            animation: _barSlideAnimation,
            builder: (context, child) {
              final offset = (1.0 - _barSlideAnimation.value) * 150;
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(
                    opacity: _barFadeAnimation.value.clamp(0.0, 1.0),
                    child: child!,
                  ),
                ),
              );
            },
            child: _buildFloatingBar(context, isAr),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              product.slug.contains('meal') || product.slug.contains('food')
                  ? Icons.restaurant_outlined
                  : product.slug.contains('umbrella')
                  ? Icons.beach_access_outlined
                  : Icons.water_drop_outlined,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, bool isAr) {
    final product = _selectedProduct!;
    final presets = product.validQuantities;
    final min = product.minQuantity;

    String itemNameEn(int qty) {
      final isPlural = qty > 1;
      if (product.slug.contains('meal') || product.slug.contains('food')) {
        return isPlural ? 'Meals' : 'Meal';
      } else if (product.slug.contains('umbrella')) {
        return isPlural ? 'Umbrellas' : 'Umbrella';
      }
      return isPlural ? 'Bottles' : 'Bottle';
    }

    String itemNameAr(int qty) {
      if (product.slug.contains('meal') || product.slug.contains('food')) {
        return 'وجبة';
      } else if (product.slug.contains('umbrella')) {
        return 'مظلة';
      }
      return 'زجاجة';
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
                  isAr ? 'اختر تأثيرك' : 'Select Your Impact',
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
                childAspectRatio: 2.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final qty = presets[index];
                final price = qty * (product.price + product.deliveryFee);
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? '$qty ${itemNameAr(qty)}'
                              : '$qty ${itemNameEn(qty)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),

                        Text(
                          isAr
                              ? 'ر.س ${price.toInt()}'
                              : 'SAR ${price.toInt()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isAr
                  ? 'أو أدخل كمية مخصصة (الأدنى. $min)'
                  : 'Or enter custom quantity (min. $min)',
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
                controller: _customController,
                focusNode: _customFocusNode,
                cursorColor: Colors.grey,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTap: () {
                  setState(() {
                    _isCustomMap[product.id] = true;
                    _selectedQuantities.remove(product.id);
                    _updateBarAnimation();
                  });
                },
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= min) {
                    setState(() {
                      _selectedQuantities[product.id] = parsed;
                    });
                    _updateBarAnimation();
                  } else {
                    setState(() {
                      _selectedQuantities.remove(product.id);
                    });
                    _updateBarAnimation();
                  }
                },
                decoration: InputDecoration(
                  suffixText: isAr ? itemNameAr(2) : itemNameEn(2),
                  suffixStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: isAr ? 'أدخل الكمية' : 'Enter quantity',
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
                label: Text(isAr ? 'إضافة ملاحظة' : 'Add note'),
                style: TextButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2381A6),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
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
                          isAr
                              ? 'ملاحظة - ${product.localizedName(isAr)}'
                              : 'Note - ${product.localizedName(isAr)}',
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
            if (product.deliveryFee > 0 &&
                _selectedQuantities[product.id] != null) ...[
              const SizedBox(height: 12),
              Text(
                isAr
                    ? '* شامل ر.س ${(_selectedQuantities[product.id]! * product.deliveryFee).toInt()} توصيل'
                    : '* Incl. SAR ${(_selectedQuantities[product.id]! * product.deliveryFee).toInt()} delivery',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context, bool isAr) {
    final total = _totalAmount;
    double deliveryTotal = 0.0;
    for (var product in widget.campaign.products) {
      final qty = _selectedQuantities[product.id];
      if (qty != null) {
        deliveryTotal += product.deliveryFee * qty;
      }
    }

    return Container(
      margin: const EdgeInsets.all(
        16,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                isAr ? 'المبلغ المستحق' : 'Payable Amount',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} ر.س'
                    : '${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} SAR',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102840),
                ),
              ),
              if (deliveryTotal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isAr
                        ? 'شامل ر.س ${deliveryTotal.toInt()} رسوم التوصيل'
                        : 'Inclusive of SAR ${deliveryTotal.toInt()} delivery charge',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_hasAnySelection) {
                _showDonationTypeDialog(context, isAr);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6A8C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              isAr ? 'متابعة' : 'Continue',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, color: Colors.black87),
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
                            title: isAr ? 'شهري' : 'Monthly',
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
                        onPressed: () async {
                          final localIsAr =
                              Localizations.localeOf(context).languageCode ==
                              'ar';
                          // Prepare items for checkout
                          final List<Map<String, dynamic>> items = [];

                          _selectedQuantities.forEach((productId, qty) {
                            if (qty > 0) {
                              final note = _productNotes[productId];
                              final item = <String, dynamic>{
                                'productId': productId,
                                'quantity': qty,
                              };
                              if (note != null && note.trim().isNotEmpty) {
                                item['note'] = note.trim();
                              }
                              items.add(item);
                            }
                          });

                          if (selectedType == 'monthly') {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SubscriptionPlanSelectionPage(
                                  checkoutItems: items,
                                  orderStates: const [],
                                  campaignId: widget.campaign.id,
                                ),
                              ),
                            );
                            return;
                          }

                          showDialog(
                            context: ctx,
                            barrierDismissible: false,
                            builder: (BuildContext loadingCtx) {
                              return const Center(
                                child: WaterLoadingIndicator(),
                              );
                            },
                          );

                          try {
                            final apiService = ApiService();
                            final response = await apiService
                                .createCheckoutCampaign(
                                  campaignId: widget.campaign.id,
                                  items: items,
                                );
                            log(
                              'createCheckoutCampaign response: ${response.data}',
                            );

                            final checkoutDataMap = response.data['data'];
                            final checkoutData = Checkout.fromJson(
                              checkoutDataMap,
                            );

                            Navigator.pop(ctx); // Close loading dialog
                            Navigator.pop(ctx); // Close donation type dialog

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContributionDetailsPage(
                                  orderStates: const [], // Empty for campaigns
                                  donationType: localIsAr
                                      ? (selectedType == 'one_time'
                                            ? 'تبرع لمرة واحدة'
                                            : 'تبرع شهري متكرر')
                                      : (selectedType == 'one_time'
                                            ? 'One-time Donation'
                                            : 'Recurring Donation'),
                                  checkoutData: checkoutData,
                                ),
                              ),
                            );
                          } catch (e) {
                            Navigator.pop(ctx); // Close loading dialog
                            log('Error creating checkout: $e', error: e);
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
                        },
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
}
