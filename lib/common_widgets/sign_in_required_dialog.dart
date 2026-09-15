import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/authentication/login.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';

/// What a guest just tried to do. Each value picks the sentence the prompt
/// leads with, so the ask reads as being about that action rather than as a
/// generic wall.
enum GuestAction { campaign, checkout, notifications, orders, impact, support }

extension GuestActionMessage on GuestAction {
  String message(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case GuestAction.campaign:
        return l10n.sign_in_required_campaign;
      case GuestAction.checkout:
        return l10n.sign_in_required_checkout;
      case GuestAction.notifications:
        return l10n.sign_in_required_notifications;
      case GuestAction.orders:
        return l10n.sign_in_required_orders;
      case GuestAction.impact:
        return l10n.sign_in_required_impact;
      case GuestAction.support:
        return l10n.sign_in_required_support;
    }
  }
}

/// The gate in front of everything guest mode cannot reach.
///
/// A guest browses on the public endpoints (see `ApiService.publicPaths`) and
/// can walk the donation flow as far as picking a package. Every step past
/// that needs a customer token, so it routes through [guard] first: signed-in
/// users pass straight through, and guests get the prompt for that specific
/// action instead of a request that would come back 401.
class SignInRequired {
  const SignInRequired._();

  /// Whether the caller may go ahead. Returns true immediately for a signed-in
  /// user; for a guest it shows the prompt for [action] and returns false.
  ///
  ///     if (!await SignInRequired.guard(context, GuestAction.checkout)) return;
  static Future<bool> guard(BuildContext context, GuestAction action) async {
    if (!AuthStorage.isGuest) return true;
    await show(context, action);
    return false;
  }

  /// Shows the prompt for [action]. Prefer [guard] — this is for callers that
  /// have already established the user is a guest.
  static Future<void> show(BuildContext context, GuestAction action) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _SignInRequiredDialog(action: action),
    );
  }

  /// Leaves guest mode and drops the user on the login screen, clearing the
  /// stack behind them so guest-mode pages can't be popped back to.
  static Future<void> goToLogin(BuildContext context) async {
    // Resolved before the await so nothing reaches for a BuildContext that may
    // have gone by the time storage has been written.
    final navigator = Navigator.of(context, rootNavigator: true);
    await AuthStorage.exitGuestMode();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }
}

class _SignInRequiredDialog extends StatelessWidget {
  const _SignInRequiredDialog({required this.action});

  final GuestAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.buttonBlueDark,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sign_in_required,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              action.message(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.buttonBlueDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: AppColors.buttonBlueDark),
                      ),
                    ),
                    child: Text(
                      l10n.not_now,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // No pop first: showDialog puts this on the root
                    // navigator, so clearing the stack takes the prompt with
                    // it.
                    onPressed: () => SignInRequired.goToLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBlueDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      l10n.sign_in,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-panel stand-in for a screen a guest can't load at all — the orders
/// tab, for instance, which has nothing to show without a customer session.
class GuestSignInPanel extends StatelessWidget {
  const GuestSignInPanel({
    super.key,
    required this.action,
    this.icon = Icons.lock_outline_rounded,
  });

  final GuestAction action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.buttonBlueDark, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.sign_in_required,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              action.message(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => SignInRequired.goToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  l10n.sign_in,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
