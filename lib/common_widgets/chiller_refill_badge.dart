import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

/// The "Refill" pill marking an order that tops up a chiller the customer
/// already owns, rather than a standalone water order.
///
/// Shown wherever such an order is listed or opened, so a refill is
/// recognisable without reading the product line — the orders list card and
/// the booking details page. Gate it on `OrderResponseModel.isChillerRefill`.
///
/// Follows the receipt badges in `payment_method_badge.dart`: a tinted pill
/// with an icon and a label, so it sits alongside them without restyling.
class ChillerRefillBadge extends StatelessWidget {
  const ChillerRefillBadge({super.key, this.compact = false});

  /// Drops the pill to the size that fits on a list card, where it shares a
  /// row with the order number rather than standing on its own.
  final bool compact;

  /// The chillers blue, matching the chiller cards elsewhere in the app.
  static const _color = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 11 : 13;
    final double iconSize = compact ? 13 : 16;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded, size: iconSize, color: _color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            AppLocalizations.of(context)!.chiller_refill,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
