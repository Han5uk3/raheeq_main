import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';

/// The delivery calendar legend's colours. Subscription statuses reuse them so
/// a subscription reads the same as the deliveries under it.
class SubscriptionStatusColors {
  static const Color delivered = Colors.green;
  static const Color upcoming = AppColors.buttonBlueDark;
  static const Color cancelled = AppColors.grey;
}

/// A subscription's status pill: a dot and the localized status on a tint of
/// its colour, as the recurring orders list and subscription details show it.
///
/// Green while the subscription runs or once it has completed, blue before it
/// starts, grey once it has stopped.
class SubscriptionStatusBadge extends StatelessWidget {
  const SubscriptionStatusBadge({super.key, required this.status});

  /// The raw `status` string from the subscription payload.
  final String status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final (label, color) = switch (status.toLowerCase().trim()) {
      'active' => (loc.status_active, SubscriptionStatusColors.delivered),
      'completed' => (loc.status_completed, SubscriptionStatusColors.delivered),
      'pending' => (loc.status_pending, SubscriptionStatusColors.upcoming),
      'cancelled' => (loc.status_cancelled, SubscriptionStatusColors.cancelled),
      'expired' => (loc.status_expired, SubscriptionStatusColors.cancelled),
      'failed' => (loc.status_failed, SubscriptionStatusColors.cancelled),
      // A status this build has no string for is shown as sent, not hidden.
      _ => (_humanize(status), SubscriptionStatusColors.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static String _humanize(String status) => status.isEmpty
      ? ''
      : status[0].toUpperCase() +
            status.substring(1).toLowerCase().replaceAll('_', ' ');
}
