import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/common_widgets/sign_in_required_dialog.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/order/order_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/formatters.dart';

// Every text row in a card reserves the same height across the whole list, so
// one card whose text wraps cannot shift the rows on the cards beside it — the
// list sizes every card to the tallest, and without this the slack collects
// under the price instead. The reserved height is measured, not assumed: a row
// only takes two lines when some card actually needs two.
//
// Line height is pinned rather than left to the font so that the reserved box
// and the rendered text always agree.
const double _slotLineHeight = 1.25;
const int _slotMaxLines = 2;

const double _slotTitleFontSize = 12;
const double _slotSubtitleFontSize = 9;
const double _slotPriceFontSize = 14;

const double _slotCardWidth = 125;
const double _slotCardMargin = 4; // Card's own default margin
const double _slotContentPadding = 8; // horizontal padding inside the card

/// Width the card's text actually gets to lay out in.
const double _slotTextWidth =
    _slotCardWidth - (_slotCardMargin * 2) - (_slotContentPadding * 2);

/// How many lines each text row of a card reserves. Shared by every card in the
/// list so their rows line up.
class _SlotTextLines {
  final int title;
  final int subtitle;
  final int price;

  const _SlotTextLines({
    required this.title,
    required this.subtitle,
    required this.price,
  });
}

/// Lines the longest of [texts] needs at [_slotTextWidth], capped at
/// [_slotMaxLines]. Returns 0 when every entry is blank, so a row that no card
/// fills reserves nothing at all.
int _measureLines(BuildContext context, List<String> texts, TextStyle style) {
  // Measure through the inherited style so the family, fallbacks and the bold
  // setting all match what Text will actually render.
  var effective = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  final textScaler = MediaQuery.textScalerOf(context);
  final textDirection = Directionality.of(context);

  var lines = 0;
  for (final text in texts) {
    if (text.trim().isEmpty) continue;
    final painter = TextPainter(
      text: TextSpan(text: text, style: effective),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: _slotMaxLines,
    )..layout(maxWidth: _slotTextWidth);
    final measured = painter.computeLineMetrics().length;
    painter.dispose();
    if (measured > lines) lines = measured;
    if (lines >= _slotMaxLines) break;
  }
  return lines;
}

/// Height of a text row reserving [lines] lines at [fontSize].
double _slotBlockHeight(BuildContext context, double fontSize, int lines) =>
    MediaQuery.textScalerOf(context).scale(fontSize) * _slotLineHeight * lines;

// The card's three strings. Measuring and rendering both go through these, so
// the reserved height cannot drift away from what is drawn.

String _slotTitleText(_ProductSlot slot, bool isAr) =>
    '${slot.quantity} ${slot.product.localizedName(isAr)}';

String _slotSubtitleText(_ProductSlot slot, bool isAr) =>
    (isAr ? slot.product.messageAr : slot.product.message) ?? '';

String _slotPriceText(BuildContext context, _ProductSlot slot) {
  final total = slot.product.price * slot.quantity;
  return '\u202A${AppLocalizations.of(context)!.sar_currency} '
      '${Formatters.formatPrice(total, decimals: 0)}\u202C';
}

// A lightweight model to represent one "slot" in the horizontal list
class _ProductSlot {
  final Product product;
  final bool isChiller;
  final int quantity;

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

  /// Set when the water is a refill for a chiller the user already owns — see
  /// [ReviewOrderPage.chillerRefillSubOrderId].
  final String? chillerRefillSubOrderId;

  const ChooseWaterPackageScreen({
    super.key,
    required this.selectedCategories,
    required this.availableProducts,
    this.chillerRefillSubOrderId,
  });

  @override
  State<ChooseWaterPackageScreen> createState() =>
      _ChooseWaterPackageScreenState();

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required List<SelectedCategoryItem> selectedCategories,
    required List<Product> availableProducts,
    String? chillerRefillSubOrderId,
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
        chillerRefillSubOrderId: chillerRefillSubOrderId,
      ),
    );
  }
}

class _ChooseWaterPackageScreenState extends State<ChooseWaterPackageScreen> {
  String? _selectedChillerSlotId;
  String? _selectedCartonSlotId;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _autoSelectFirstCarton();
  }

  void _autoSelectFirstCarton() {
    final cartons = widget.availableProducts.where(
      (p) => p.serialNumber == 1 || p.serialNumber == 4,
    );

    for (final carton in cartons) {
      final quantities =
          carton.presetQuantities.where((q) => q >= carton.minQuantity).toList()
            ..sort();
      if (quantities.isNotEmpty) {
        _selectedCartonSlotId = '${carton.id}_${quantities.first}';
        break;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build the flat list of slots ────────────────────────────────────────────

  List<_ProductSlot> get _slots {
    final slots = <_ProductSlot>[];

    // 1. Chiller first (One card per preset quantity)
    final chillers = widget.availableProducts.where((p) => p.serialNumber == 2);

    for (final chiller in chillers) {
      final quantities =
          chiller.presetQuantities
              .where((q) => q >= chiller.minQuantity)
              .toList()
            ..sort();
      for (final qty in quantities) {
        slots.add(
          _ProductSlot(product: chiller, isChiller: true, quantity: qty),
        );
      }
    }

    // 2. One card per preset quantity for every carton product
    final cartons = widget.availableProducts.where(
      (p) => p.serialNumber == 1 || p.serialNumber == 4,
    );

    for (final carton in cartons) {
      final quantities =
          carton.presetQuantities.where((q) => q >= carton.minQuantity).toList()
            ..sort();
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

  Future<void> _navigateToReview() async {
    if (!_isContinueEnabled) return;

    // Guests are free to browse the packages; leaving this sheet for the order
    // review page is where the customer session becomes necessary.
    if (!await SignInRequired.guard(context, GuestAction.checkout)) return;
    if (!mounted) return;

    final allSlots = _slots;
    final List<SelectedProduct> selectedProducts = [];

    if (_selectedChillerSlotId != null) {
      final selectedChiller = allSlots.firstWhere(
        (s) => s.id == _selectedChillerSlotId,
      );
      selectedProducts.add(
        SelectedProduct(
          product: selectedChiller.product,
          quantity: selectedChiller.quantity,
        ),
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
        builder: (_) => ReviewOrderPage(
          orderStates: orderStates,
          chillerRefillSubOrderId: widget.chillerRefillSubOrderId,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.choose_water_package;

    final slots = _slots;

    // Measured once for the whole list: every card reserves the same number of
    // lines per row, and a row only grows to two lines if some card needs two.
    final lines = _SlotTextLines(
      title: _measureLines(
        context,
        [for (final s in slots) _slotTitleText(s, isAr)],
        const TextStyle(
          fontSize: _slotTitleFontSize,
          height: _slotLineHeight,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: _measureLines(
        context,
        [for (final s in slots) _slotSubtitleText(s, isAr)],
        const TextStyle(
          fontSize: _slotSubtitleFontSize,
          height: _slotLineHeight,
        ),
      ),
      price: _measureLines(
        context,
        [for (final s in slots) _slotPriceText(context, s)],
        const TextStyle(
          fontSize: _slotPriceFontSize,
          height: _slotLineHeight,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

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
            child: Container(width: 70, height: 4),
          ),

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
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal slot list. The row sizes itself to the tallest card and
          // stretches every other card to match, so no card carries dead space.
          // Scrollbar (and CupertinoScrollbar on iOS) default their padding
          // to MediaQuery.paddingOf(context) and subtract it from the
          // thumb's position — meant for scrollbars that reach a physical
          // screen edge. This one sits mid-sheet, so on devices with a
          // bottom safe-area inset (home indicator, gesture nav bar) that
          // default shifts the thumb up into the card row. Removing the
          // ambient bottom padding here keeps the thumb inside the gutter
          // reserved for it on every device.
          MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: Scrollbar(
              controller: _scrollController,
              interactive: true,
              thumbVisibility: true,
              thickness: 4.0,
              radius: const Radius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 15.0,
                ), // Dedicated space for scrollbar, prevents overlap
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(slots.length, (index) {
                        final slot = slots[index];
                        final isSelected = _isSlotSelected(slot);

                        return Padding(
                          padding: EdgeInsetsDirectional.only(
                            bottom: 16,
                            start: index == 0 ? 16.0 : 2.0,
                            end: index == slots.length - 1 ? 16.0 : 2.0,
                          ),
                          child: _buildSlotCard(
                            slot: slot,
                            isSelected: isSelected,
                            onTap: () => _toggleSlot(slot),
                            isAr: isAr,
                            lines: lines,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 12,
            ),
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
        ],
      ),
    );
  }

  /// One text row of a card, occupying exactly [lines] lines whether or not the
  /// text fills them. Top-aligned so first lines stay level across cards.
  Widget _slotTextRow({
    required String text,
    required double fontSize,
    required int lines,
    required TextStyle style,
  }) {
    return SizedBox(
      height: _slotBlockHeight(context, fontSize, lines),
      width: double.infinity,
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          text,
          style: style.copyWith(fontSize: fontSize, height: _slotLineHeight),
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSlotCard({
    required _ProductSlot slot,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAr,
    required _SlotTextLines lines,
  }) {
    final product = slot.product;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _slotCardWidth,
        child: Card(
          color: Colors.white,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
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
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.water_drop,
                              color: AppColors.buttonBlueDark,
                              size: 40,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.water_drop,
                            color: AppColors.buttonBlueDark,
                            size: 40,
                          ),
                        ),
                ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,

                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Product name
                      _slotTextRow(
                        text: _slotTitleText(slot, isAr),
                        fontSize: _slotTitleFontSize,
                        lines: lines.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      if (lines.subtitle > 0) ...[
                        const SizedBox(height: 8),
                        _slotTextRow(
                          text: _slotSubtitleText(slot, isAr),
                          fontSize: _slotSubtitleFontSize,
                          lines: lines.subtitle,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],

                      if (lines.price > 0) ...[
                        const SizedBox(height: 5),
                        _slotTextRow(
                          text: _slotPriceText(context, slot),
                          fontSize: _slotPriceFontSize,
                          lines: lines.price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ],
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
