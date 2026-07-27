import 'package:flutter/material.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/pages/home/pages/orders_tab.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

enum PaymentStatus { success, failed, pendingApproval, serverError, cancelled }

class PaymentStatusPage extends StatefulWidget {
  final PaymentStatus status;
  final String? message;
  final String? orderId;
  final bool isAr;
  final VoidCallback? onRetry;

  const PaymentStatusPage({
    super.key,
    required this.status,
    this.message,
    this.orderId,
    this.isAr = false,
    this.onRetry,
  });

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String description = '';
    Color color = AppColors.buttonBlueDark;
    Color lightColor = Colors.white;
    IconData fallbackIcon = Icons.info;

    switch (widget.status) {
      case PaymentStatus.success:
        title = AppLocalizations.of(context)!.payment_successful;
        description = AppLocalizations.of(context)!.thank_you_for_your_donation;
        color = AppColors.buttonBlueDark;
        lightColor = AppColors.buttonBlueDark.withValues(alpha: 0.1);
        fallbackIcon = Icons.check_circle_outline;
        break;
      case PaymentStatus.failed:
        title = AppLocalizations.of(context)!.payment_failed;
        description =
            widget.message ??
            AppLocalizations.of(
              context,
            )!.an_error_occurred_while_processing_the_payment;
        color = Colors.red;
        lightColor = Colors.red.withValues(alpha: 0.1);
        fallbackIcon = Icons.error_outline;
        break;
      case PaymentStatus.pendingApproval:
        title = AppLocalizations.of(context)!.pending_approval;
        description = AppLocalizations.of(context)!.order_received_iban_message;
        color = Colors.yellow.shade700;
        lightColor = Colors.yellow.shade700.withValues(alpha: 0.1);
        fallbackIcon = Icons.access_time;
        break;
      case PaymentStatus.serverError:
        title = widget.isAr ? 'خطأ في الخادم' : 'Server Error';
        description =
            widget.message ??
            (widget.isAr
                ? 'سيتم التحقق من الدفع بمجرد عودتنا ومعالجة طلبك.'
                : 'Payment will be verified as soon as we are back and process your order.');
        color = Colors.orange;
        lightColor = Colors.orange.withValues(alpha: 0.1);
        fallbackIcon = Icons.cloud_off;
        break;
      case PaymentStatus.cancelled:
        title = AppLocalizations.of(context)!.status_cancelled;
        description =
            widget.message ??
            AppLocalizations.of(context)!.payment_was_cancelled;
        color = Colors.redAccent;
        lightColor = Colors.redAccent.withValues(alpha: 0.1);
        fallbackIcon = Icons.cancel_outlined;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Background Gradient Element
          Positioned(
            top: -100,
            right: widget.isAr ? null : -100,
            left: widget.isAr ? -100 : null,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.15), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.08),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon or Lottie Animation
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.5, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: lightColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      fallbackIcon,
                                      size: 80,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (widget.status != PaymentStatus.success) ...{
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    letterSpacing: -0.5,
                                    height: 1.3,
                                  ),
                                ),
                              },

                              if (widget.status == PaymentStatus.success &&
                                  widget.orderId != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        '${AppLocalizations.of(context)!.order_number}: ${widget.orderId}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 100),
                              // Description
                              Text(
                                description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom Actions
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if ((widget.status == PaymentStatus.failed ||
                                  widget.status == PaymentStatus.cancelled) &&
                              widget.onRetry != null) ...[
                            _buildPrimaryButton(
                              context,
                              text: AppLocalizations.of(context)!.retry_payment,
                              onPressed: widget.onRetry!,
                              color: color,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (widget.status == PaymentStatus.success ||
                              widget.status ==
                                  PaymentStatus.pendingApproval) ...[
                            _buildSecondaryButton(
                              context,
                              text: AppLocalizations.of(
                                context,
                              )!.back_to_orders,
                              onPressed: () {
                                HomeTab.clearBasket();
                                OrdersTab.switchInnerTabNotifier.value = 0;
                                HomeScreen.switchTabNotifier.value = 1;
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                          ] else ...[
                            _buildSecondaryButton(
                              context,
                              text: AppLocalizations.of(context)!.back_to_home,
                              onPressed: () {
                                if (widget.status ==
                                    PaymentStatus.serverError) {
                                  HomeTab.clearBasket();
                                }
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    Color color = AppColors.buttonBlueDark,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.buttonBlueDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
