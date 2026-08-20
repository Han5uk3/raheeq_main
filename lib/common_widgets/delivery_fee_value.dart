import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/formatters.dart';

/// The amount side of a "Delivery Fee" row.
///
/// A free delivery never reads as a bare `0`: the fee the customer would have
/// paid is struck through and "Free" sits next to it. The two screens that show
/// delivery fees — booking details and contribution details — style their rows
/// differently, so each passes its own [baseStyle] and only the free-delivery
/// treatment is shared here.
class DeliveryFeeValue extends StatelessWidget {
  const DeliveryFeeValue({
    super.key,
    required this.isFree,
    required this.amount,
    required this.baseStyle,
  });

  /// Whether delivery ended up free.
  final bool isFree;

  /// The fee to show. When [isFree], this is the original fee that gets struck
  /// through; null means there is no original fee to show, leaving just "Free".
  final double? amount;

  /// The row's own text style, which the struck-through amount is muted from.
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Pinned left-to-right so the currency and digits keep their order inside
    // an Arabic line, matching every other price in the app.
    Widget amountText() => Text(
      '${l10n.sar_currency} ${Formatters.formatPrice(amount ?? 0, decimals: 2)}',
      textDirection: TextDirection.ltr,
      style: isFree
          ? baseStyle.copyWith(
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            )
          : baseStyle,
    );

    if (!isFree) return amountText();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (amount != null) ...[amountText(), const SizedBox(width: 8)],
        Text(
          l10n.free,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
