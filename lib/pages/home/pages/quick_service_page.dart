import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class QuickServicePage extends StatefulWidget {
  final Category category;
  final List<Product> products;

  const QuickServicePage({
    super.key,
    required this.category,
    required this.products,
  });

  @override
  State<QuickServicePage> createState() => _QuickServicePageState();
}

class _QuickServicePageState extends State<QuickServicePage>
    with SingleTickerProviderStateMixin {
  Product? _selectedProduct;
  int? _selectedQuantity;
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();

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
  }

  @override
  void dispose() {
    _barAnimController.dispose();
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────── Helpers ───────────────────────

  double get _totalAmount {
    if (_selectedProduct == null || _selectedQuantity == null) return 0;
    return _selectedProduct!.price * _selectedQuantity!;
  }

  List<int> _validQuantities(Product product) => product.validQuantities;

  int _minQuantity(Product product) => product.minQuantity;

  // ─────────────────────── Actions ───────────────────────

  void _selectProduct(Product product) {
    final isSame =
        _selectedProduct != null && _selectedProduct!.id == product.id;
    if (isSame) return;

    _barAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedProduct = product;
          _selectedQuantity = null;
          _isCustom = false;
          _customController.clear();
        });
      }
    });
  }

  void _selectQuantity(int quantity) {
    setState(() {
      _selectedQuantity = quantity;
      _isCustom = false;
      _customFocusNode.unfocus();
    });
    _barAnimController.forward();
  }

  void _toggleCustom() {
    setState(() {
      _isCustom = !_isCustom;
      if (_isCustom) {
        _selectedQuantity = null;
        _barAnimController.reverse();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _customFocusNode.requestFocus();
        });
      }
    });
  }

  void _confirmCustom() {
    final product = _selectedProduct;
    if (product == null) return;
    final val = int.tryParse(_customController.text.trim());
    final min = _minQuantity(product);
    if (val == null || val < min) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.minimum_quantity_is(min.toString()),
        isError: true,
        bottomMargin: 130,
      );
      return;
    }
    setState(() {
      _selectedQuantity = val;
      _isCustom = false;
      _customFocusNode.unfocus();
    });
    _barAnimController.forward();
  }

  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final category = widget.category;
    final label = category.localizedLabel(isAr);
    final imageUrl = category.image;
    final subtitle = category.localizedSubtitle(isAr);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Main Scroll ──
          CustomScrollView(
            slivers: [
              // Category SliverAppBar
              _buildSliverAppBar(context, label, subtitle, imageUrl, isAr),

              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 12),
                  child: Text(
                    AppLocalizations.of(context)!.select_a_product,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // Products list
              if (widget.products.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        AppLocalizations.of(context)!.no_products_available,
                        style: const TextStyle(color: Colors.black45),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = widget.products[index];
                      return _buildProductCard(context, product, isAr);
                    }, childCount: widget.products.length),
                  ),
                ),

              // Quantity section
              if (_selectedProduct != null)
                SliverToBoxAdapter(child: _buildQuantitySection(context, isAr)),

              // Bottom padding
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _selectedQuantity != null ? 130 : 40,
                ),
              ),
            ],
          ),

          // ── Floating Bottom Bar ──
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

  // ─────────────────────── Sliver App Bar ───────────────────────

  Widget _buildSliverAppBar(
    BuildContext context,
    String title,
    String? subtitle,
    String imageUrl,
    bool isAr,
  ) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.buttonBlueDark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(backArrowIcon(context), color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.buttonBlueDark),
              errorWidget: (context, url, error) => Container(
                color: AppColors.buttonBlueDark,
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white54,
                  size: 60,
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            // Title anchored at bottom
            Positioned(
              bottom: 28,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Quick Services" chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.quick_services,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Product Card ───────────────────────

  Widget _buildProductCard(BuildContext context, Product product, bool isAr) {
    final name = product.localizedName(isAr);
    final subtitle = product.localizedSubtitle(isAr);
    final price = product.price;
    final imageUrl = product.image;
    final isHighNeed = product.isHighNeed;
    final isSelected =
        _selectedProduct != null && _selectedProduct!.id == product.id;

    return GestureDetector(
      onTap: () => _selectProduct(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsetsDirectional.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.buttonBlueDark.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF0F7FB),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: WaterLoadingIndicator(size: 30)),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.water_drop,
                    color: AppColors.buttonBlue,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isHighNeed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.high_need,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F9FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} ${AppLocalizations.of(context)!.sar_currency} / ${AppLocalizations.of(context)!.unit}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.buttonBlueDark
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.buttonBlueDark
                      : Colors.grey.shade300,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Quantity Section ───────────────────────

  Widget _buildQuantitySection(BuildContext context, bool isAr) {
    final product = _selectedProduct!;
    final presets = _validQuantities(product);
    final min = _minQuantity(product);
    final name = product.localizedName(isAr);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F9FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.numbers_rounded,
                    color: AppColors.buttonBlueDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.select_quantity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.for_name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                // Preset quantity chips
                ...presets.map((qty) {
                  final isSelected = _selectedQuantity == qty && !_isCustom;
                  return GestureDetector(
                    onTap: () => _selectQuantity(qty),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.buttonBlueDark
                            : const Color(0xFFF4F8FB),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.buttonBlueDark
                              : const Color(0xFFE2EAF0),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.buttonBlueDark.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        qty.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }),

                // Custom chip
                GestureDetector(
                  onTap: _toggleCustom,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustom
                          ? const Color(0xFF1A6A8F)
                          : const Color(0xFFF4F8FB),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _isCustom
                            ? const Color(0xFF1A6A8F)
                            : const Color(0xFFE2EAF0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: _isCustom ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context)!.custom,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isCustom ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Custom input
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _isCustom
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              cursorColor: AppColors.buttonBlueDark,

                              controller: _customController,
                              focusNode: _customFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (_) => _confirmCustom(),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.enter_quantity_min_min,
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black38,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF4F8FB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2EAF0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2EAF0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.buttonBlueDark,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _confirmCustom,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.buttonBlueDark,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.buttonBlueDark.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Minimum hint
            if (!_isCustom) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppLocalizations.of(context)!.minimum_order_min_units,
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Floating Bar ───────────────────────

  Widget _buildFloatingBar(BuildContext context, bool isAr) {
    final product = _selectedProduct;
    final price = product?.price ?? 0.0;
    final qty = _selectedQuantity ?? 0;
    final total = _totalAmount;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        24,
        18,
        24,
        MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Amount info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.total_amount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    key: ValueKey(total),
                    "${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} ${AppLocalizations.of(context)!.sar_currency}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonBlueDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (qty > 0)
                  Text(
                    "$qty ${AppLocalizations.of(context)!.units} × ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} ${AppLocalizations.of(context)!.sar_currency}",
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Continue button
          GestureDetector(
            onTap: () {
              // TODO: Navigate to payment/confirmation step
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A6A8F), Color(0xFF11506B)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.continue_btn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      forwardArrowIcon(context),
                      color: Colors.white,
                      size: 15,
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
}
