import 'package:material_symbols_icons/symbols.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/models/campaign.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/donation_type_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_plans_bottom_sheet.dart';
import 'package:raheeq_main/common_widgets/subscription_details_bottom_sheet.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/services/snackbar_insets_services.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
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
  Map<String, String> _customQuantityText = {};
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  Map<String, String> _productNotes = {};
  Map<String, bool> _isNoteRevealed = {};
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isLoading = false;
  final ScrollController _productScrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  bool get _hasAnySelection => _selectedQuantities.values.any((qty) => qty > 0);

  /// Products where the user typed a custom quantity below the product's
  /// minimum allowed quantity. These are silently excluded from
  /// `_selectedQuantities`, so they must be checked separately before checkout.
  List<Product> _getBelowMinimumProducts() {
    final invalid = <Product>[];
    for (final product in widget.campaign.products) {
      if (_isCustomMap[product.id] != true) continue;
      final text = _customQuantityText[product.id];
      if (text == null || text.isEmpty) continue;
      final parsed = int.tryParse(text);
      if (parsed != null && parsed < product.minQuantity) {
        invalid.add(product);
      }
    }
    return invalid;
  }

  @override
  void initState() {
    super.initState();
    debugPrint(
      'CampaignDetailPage: ${widget.campaign.id} has ${widget.campaign.products.length} products',
    );
    SnackbarInsets.setBottomInset(kBottomNavigationBarHeight);

    // Auto-select first product if available
    if (widget.campaign.products.isNotEmpty) {
      _selectedProduct = widget.campaign.products.first;
    }

    _productScrollController.addListener(_updateScrollButtonState);

    // Initialize scroll button state after the controller attaches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollButtonState();
    });
  }

  void _updateScrollButtonState() {
    if (!_productScrollController.hasClients) return;
    if (!mounted) return;
    final pos = _productScrollController.position;
    final atStart = pos.pixels <= pos.minScrollExtent + 1;
    final atEnd = pos.pixels >= pos.maxScrollExtent - 1;
    // "canScrollStart" = can scroll toward the start (left in LTR, right in RTL)
    // "canScrollEnd" = can scroll toward the end (right in LTR, left in RTL)
    final newCanScrollStart = !atStart;
    final newCanScrollEnd = !atEnd;
    if (newCanScrollStart != _canScrollLeft ||
        newCanScrollEnd != _canScrollRight) {
      setState(() {
        _canScrollLeft = newCanScrollStart;
        _canScrollRight = newCanScrollEnd;
      });
    }
  }

  @override
  void dispose() {
    SnackbarInsets.clear();
    _customController.dispose();
    _customFocusNode.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _productScrollController.removeListener(_updateScrollButtonState);
    _productScrollController.dispose();
    super.dispose();
  }

  void _scrollProducts({required bool forward}) {
    if (!_productScrollController.hasClients) return;
    final pos = _productScrollController.position;
    final scrollAmount = pos.viewportDimension * 0.65;
    // forward = toward maxScrollExtent, backward = toward minScrollExtent
    // Flutter handles RTL internally for horizontal ListViews,
    // so we always use the same pixel direction.
    final target = forward
        ? (pos.pixels + scrollAmount).clamp(
            pos.minScrollExtent,
            pos.maxScrollExtent,
          )
        : (pos.pixels - scrollAmount).clamp(
            pos.minScrollExtent,
            pos.maxScrollExtent,
          );
    _productScrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          _updateScrollButtonState();
        });
  }

  void _selectProduct(Product product) {
    if (_selectedProduct?.id == product.id) return;
    setState(() {
      _selectedProduct = product;
      _customFocusNode.unfocus();
      _noteFocusNode.unfocus();
      if (_isCustomMap[product.id] == true) {
        _customController.text = _customQuantityText[product.id] ?? '';
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
    if (quantity < _selectedProduct!.minQuantity) return;
    setState(() {
      if (_selectedQuantities[_selectedProduct!.id] == quantity &&
          _isCustomMap[_selectedProduct!.id] != true) {
        _selectedQuantities.remove(_selectedProduct!.id);
      } else {
        _selectedQuantities[_selectedProduct!.id] = quantity;
        _isCustomMap[_selectedProduct!.id] = false;
        _customQuantityText.remove(_selectedProduct!.id);
        _customFocusNode.unfocus();
        _customController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = widget.campaign.localizedTitle(isAr);
    final products = widget.campaign.products;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildFloatingBar(context, isAr),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
          ),

          AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppBar(
                    title: title,
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.discount_outlined,
                                      size: 16,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        overflow: TextOverflow.ellipsis,
                                        _selectedProduct?.localizedMessage(
                                              isAr,
                                            ) ??
                                            "",
                                        maxLines: 3,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 12,
                                  end: 12,
                                  top: 12, // spacing after banner
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? 50
                                      : 130, // extra space for bottom bar and keyboard
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
                            final screenWidth = MediaQuery.of(
                              context,
                            ).size.width;

                            int visibleCount = products.length;
                            if (visibleCount == 0) visibleCount = 1;
                            if (visibleCount > 3) visibleCount = 2;

                            final spacing = 12.0 * (visibleCount - 1);
                            // When > 3 items, account for scroll buttons and their spacing:
                            // 2 buttons * 35px + 4 SizedBox spacers * 8px = 102px
                            final buttonSpace = products.length > 3
                                ? (35.0 * 2 + 8.0 * 4)
                                : 0.0;
                            final totalTakenSpace =
                                32.0 + // Container margin (16*2)
                                (products.length > 3
                                    ? 0.0
                                    : 24.0) + // ListView padding (12*2) only when no buttons
                                spacing +
                                buttonSpace;
                            final itemWidth =
                                (screenWidth - totalTakenSpace) / visibleCount;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                  child: products.length > 3
                                      ? Row(
                                          children: [
                                            SizedBox(width: 8),
                                            _buildScrollButton(
                                              icon: Icons.chevron_left,
                                              onTap: _canScrollLeft
                                                  ? () => _scrollProducts(
                                                      forward: false,
                                                    )
                                                  : null,
                                              enabled: _canScrollLeft,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: ListView.separated(
                                                controller:
                                                    _productScrollController,
                                                physics:
                                                    const ClampingScrollPhysics(),

                                                scrollDirection:
                                                    Axis.horizontal,
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
                                            SizedBox(width: 8),

                                            _buildScrollButton(
                                              icon: Icons.chevron_right,
                                              onTap: _canScrollRight
                                                  ? () => _scrollProducts(
                                                      forward: true,
                                                    )
                                                  : null,
                                              enabled: _canScrollRight,
                                            ),
                                            SizedBox(width: 8),
                                          ],
                                        )
                                      : ListView.separated(
                                          physics:
                                              const ClampingScrollPhysics(),
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
          color: isSelected
              ? AppColors.buttonBlueDark
              : AppColors.buttonBlueLight,
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
                  : product.serialNumber == 1
                  ? Symbols.package_2
                  : product.serialNumber == 2
                  ? Icons.kitchen_outlined
                  : product.serialNumber == 7
                  ? Icons.chair_alt_outlined
                  : Icons.water_drop_outlined,
              color: isSelected ? Colors.white : AppColors.buttonBlueDark,
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.buttonBlueDark,
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

  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return IgnorePointer(
      ignoring: !enabled,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 35,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.buttonBlueDark.withValues(alpha: 0.85)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, bool isAr) {
    final product = _selectedProduct!;
    final presets = product.validQuantities;
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
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.buttonBlueDark,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    AppLocalizations.of(context)!.select_your_impact,
                    style: TextStyle(
                      fontSize: isAr ? 14 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
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
                final price = qty * product.price;
                return GestureDetector(
                  onTap: () => _selectQuantity(qty),
                  child: Material(
                    color: Colors.white,
                    elevation:
                        _selectedQuantities[product.id] == qty &&
                            _isCustomMap[product.id] != true
                        ? 5
                        : 2,
                    borderRadius: BorderRadius.circular(12),

                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            _selectedQuantities[product.id] == qty &&
                                _isCustomMap[product.id] != true
                            ? AppColors.buttonBlueDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedQuantities[product.id] == qty &&
                                  _isCustomMap[product.id] != true
                              ? AppColors.buttonBlueDark
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsetsDirectional.only(start: 8, end: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "$qty ${isAr ? product.subtitleAr : product.subtitle}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color:
                                    _selectedQuantities[product.id] == qty &&
                                        _isCustomMap[product.id] != true
                                    ? Colors.white
                                    : AppColors.buttonBlueDark,
                              ),
                            ),
                            Text(
                              "\u202A${AppLocalizations.of(context)!.sar_currency} ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}\u202C",
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    _selectedQuantities[product.id] == qty &&
                                        _isCustomMap[product.id] != true
                                    ? Colors.white
                                    : AppColors.buttonBlueDark,
                              ),
                            ),
                          ],
                        ),
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
            Material(
              elevation: 2,
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),

              child: TextField(
                scrollPadding: const EdgeInsets.only(bottom: 200),
                cursorColor: AppColors.buttonBlueDark,
                style: const TextStyle(color: AppColors.black, fontSize: 14),
                controller: _customController,
                focusNode: _customFocusNode,

                decoration: InputDecoration(
                  suffixText: itemName(2),
                  suffixStyle: const TextStyle(
                    color: AppColors.buttonBlueDark,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: AppLocalizations.of(context)!.enter_quantity,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  hintStyle: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.buttonBlueDark,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.buttonBlueDark,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.buttonBlueDark,
                      width: 1.5,
                    ),
                  ),
                ),

                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTap: () {
                  setState(() {
                    _isCustomMap[product.id] = true;
                    _customQuantityText[product.id] = _customController.text;
                    final parsed = int.tryParse(_customController.text);
                    if (parsed != null && parsed >= min) {
                      _selectedQuantities[product.id] = parsed;
                    } else {
                      _selectedQuantities.remove(product.id);
                    }
                  });
                },
                onChanged: (val) {
                  _customQuantityText[product.id] = val;
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
              ),
            ),
            const SizedBox(height: 16),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isNoteRevealed[product.id] != true
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isNoteRevealed[product.id] = true;
                    _noteController.text = _productNotes[product.id] ?? '';
                  });
                },
                icon: const Icon(Icons.note_add_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.add_note),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                    side: BorderSide(color: AppColors.buttonBlueDark),
                  ),
                  elevation: 2,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.buttonBlueDark,
                ),
              ),
              secondChild: Material(
                elevation: 0,
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: 16,
                 
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${AppLocalizations.of(context)!.note_prefix} ${product.localizedName(isAr)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            style: const ButtonStyle(
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              
                            ),
                            onPressed: () {
                              setState(() {
                                _isNoteRevealed[product.id] = false;
                                _noteController.clear();
                                _productNotes.remove(product.id);
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        scrollPadding: const EdgeInsets.only(bottom: 200),
                        cursorColor: AppColors.buttonBlueDark,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 14,
                        ),
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        maxLines: 3,
                        onChanged: (val) {
                          _productNotes[product.id] = val;
                        },
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          hintText: AppLocalizations.of(
                            context,
                          )!.would_you_like_to_add_a_note_to_the_delivery_agent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonBlueDark,
                              width: 1.5,
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
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context, bool isAr) {
    double total = 0;
    _selectedQuantities.forEach((productId, qty) {
      final product = widget.campaign.products.firstWhere(
        (p) => p.id == productId,
      );
      total += qty * product.price;
    });

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
      child: BottomActionPill(
        isLoading: _isLoading,
        subtitleWidget: Text(
          AppLocalizations.of(context)!.payable_amount,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        titleWidget: Text(
          "\u202A${AppLocalizations.of(context)!.sar_currency} ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}\u202C",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        buttonText: AppLocalizations.of(context)!.confirm_pay,
        onButtonTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          final belowMinimumProducts = _getBelowMinimumProducts();
          if (belowMinimumProducts.isNotEmpty) {
            final message = belowMinimumProducts
                .map(
                  (product) =>
                      '${product.localizedName(isAr)}: ${AppLocalizations.of(context)!.minimum_quantity_is(product.minQuantity.toString())}',
                )
                .join('\n');
            CustomSnackbar.show(context: context, message: message, isError: true);
          } else if (_hasAnySelection) {
            if (widget.campaign.canSubscribe) {
              _showDonationTypeDialog(context, isAr);
            } else {
              _processOneTimeCheckout(context, isAr);
            }
          } else {
            CustomSnackbar.show(
              context: context,
              message: AppLocalizations.of(
                context,
              )!.select_a_product_to_continue,
              isError: true,
            );
          }
        },
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

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.createCheckoutCampaign(
        campaignId: widget.campaign.id,
        items: items,
      );
      log('createCheckoutCampaign response: ${response.data}');

      final checkoutDataMap = response.data['data'];
      final checkoutData = Checkout.fromJson(checkoutDataMap);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
