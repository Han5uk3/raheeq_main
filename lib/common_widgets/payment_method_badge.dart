import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

/// The visual identity of one payment method, resolved from the backend enum.
///
/// The seven keys the orders API can return are `CREDIT_CARD`, `APPLE_PAY`,
/// `STC_PAY`, `IBAN`, `WALLET`, `FREE` and `MANUAL`. Only the four gateway
/// methods ship artwork today, so the other three — and anything the backend
/// adds later — fall back to [icon] drawn in the method's own colour. See
/// [PaymentMethodBadge] for the assets still to be added.
class PaymentMethodStyle {
  const PaymentMethodStyle({
    required this.label,
    required this.color,
    required this.icon,
    this.asset,
    this.secondaryAsset,
  });

  /// The localized name shown on the badge.
  final String label;

  /// The method's theme colour. The badge tints its fill and border from it.
  final Color color;

  /// Drawn when [asset] is null — the placeholder standing in until the
  /// method's own artwork is added.
  final IconData icon;

  /// The method's logo, or null when no artwork ships for it yet.
  final String? asset;

  /// A second logo shown ahead of [asset], for methods that carry two marks
  /// (card payments show both Visa and Mada).
  final String? secondaryAsset;

  /// Whether this method is falling back to the placeholder icon.
  bool get usesPlaceholder => asset == null;

  /// Resolves [method] — the raw `paymentMethod` enum string — into its badge
  /// style. An empty or unrecognised key still gets a neutral badge rather
  /// than an empty space, so a new backend method never renders as a blank.
  static PaymentMethodStyle resolve(BuildContext context, String method) {
    final l10n = AppLocalizations.of(context)!;
    switch (method.toUpperCase()) {
      case 'WALLET':
        return PaymentMethodStyle(
          label: l10n.payment_method_wallet,
          color: const Color(0xFF4F46E5), // Indigo
          icon: Icons.account_balance_wallet_rounded,
        );
      case 'FREE':
        return PaymentMethodStyle(
          label: l10n.payment_method_free,
          color: const Color(0xFF0D9488), // Teal
          icon: Icons.card_giftcard_rounded,
        );
      case 'MANUAL':
        return PaymentMethodStyle(
          label: l10n.payment_method_manual,
          color: const Color(0xFFD97706), // Amber
          icon: Icons.payments_rounded,
        );
      case 'APPLE_PAY':
        return PaymentMethodStyle(
          label: l10n.payment_method_apple_pay,
          color: const Color(0xFF1F2937), // Neutral dark
          icon: Icons.phone_iphone_rounded,
          asset: 'assets/payment_method_icons/apple_pay.png',
        );
      case 'STC_PAY':
        return PaymentMethodStyle(
          label: l10n.payment_method_stc_pay,
          color: const Color(0xFF7C3AED), // Violet
          icon: Icons.smartphone_rounded,
          asset: 'assets/payment_method_icons/stc_pay.png',
        );
      case 'CREDIT_CARD':
      case 'MADA':
        return PaymentMethodStyle(
          label: l10n.payment_method_credit_card,
          color: const Color(0xFF2563EB), // Blue
          icon: Icons.credit_card_rounded,
          asset: 'assets/payment_method_icons/mada.png',
          secondaryAsset: 'assets/payment_method_icons/visa.png',
        );
      case 'IBAN':
      case 'BANK_TRANSFER':
        return PaymentMethodStyle(
          label: l10n.payment_method_iban,
          color: const Color(0xFF0284C7), // Sky blue
          icon: Icons.account_balance_rounded,
          asset: 'assets/payment_method_icons/iban.png',
        );
      default:
        return PaymentMethodStyle(
          label: method.isEmpty ? l10n.payment_method : _humanize(method),
          color: const Color(0xFF64748B), // Slate
          icon: Icons.receipt_long_rounded,
        );
    }
  }

  /// Turns an unknown `SOME_NEW_METHOD` key into "Some New Method" so an
  /// unmapped backend value still reads as words on the receipt.
  static String _humanize(String method) => method
      .toLowerCase()
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

/// The "Payment Method" pill on the order receipt: the method's logo (or its
/// placeholder icon) next to its localized name, tinted with the method's
/// colour theme.
///
/// Three methods have no artwork yet and render the placeholder icon instead.
/// Dropping these files into `assets/payment_method_icons/` and setting
/// `asset:` on the matching case in [PaymentMethodStyle.resolve] is all that is
/// needed to switch them over:
///
/// * `wallet.png` — `WALLET`
/// * `free.png` — `FREE`
/// * `manual.png` — `MANUAL`
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.method});

  /// The raw `paymentMethod` enum string from the order payload.
  final String method;

  @override
  Widget build(BuildContext context) {
    final style = PaymentMethodStyle.resolve(context, method);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.secondaryAsset != null) ...[
            _logo(style.secondaryAsset!),
            const SizedBox(width: 4),
          ],
          if (style.asset != null)
            _logo(style.asset!)
          else
            // Placeholder for the methods that ship no logo yet.
            Icon(style.icon, size: 16, color: style.color),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo(String asset) =>
      SizedBox(height: 20, width: 20, child: Image.asset(asset, fit: BoxFit.contain));
}

/// The "Payment Status" pill on the order receipt — `PAID`, `PENDING` and the
/// rest of the backend statuses, localized and colour-coded.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  /// The raw `paymentStatus` string from the order payload.
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final String label;
    final Color color;
    final IconData icon;

    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
        label = l10n.payment_status_paid;
        color = const Color(0xFF059669); // Emerald
        icon = Icons.check_circle_rounded;
      case 'AWAITING_VERIFICATION':
      case 'PENDING_APPROVAL':
        // Bank transfers sit here until the uploaded receipt is verified.
        label = l10n.payment_status_awaiting_verification;
        color = const Color(0xFFD97706); // Amber
        icon = Icons.hourglass_bottom_rounded;
      case 'PENDING':
        label = l10n.payment_status_pending;
        color = const Color(0xFFD97706); // Amber
        icon = Icons.schedule_rounded;
      case 'FAILED':
      case 'DECLINED':
        label = l10n.payment_status_failed;
        color = const Color(0xFFDC2626); // Red
        icon = Icons.error_rounded;
      case 'CANCELLED':
      case 'EXPIRED':
        label = l10n.payment_status_cancelled;
        color = const Color(0xFF64748B); // Slate
        icon = Icons.cancel_rounded;
      case 'REFUNDED':
        label = l10n.payment_status_refunded;
        color = const Color(0xFF0284C7); // Sky blue
        icon = Icons.replay_rounded;
      default:
        label = PaymentMethodStyle._humanize(status);
        color = const Color(0xFF64748B); // Slate
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
