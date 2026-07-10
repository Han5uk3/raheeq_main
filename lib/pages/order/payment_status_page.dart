import 'package:flutter/material.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

enum PaymentStatus { success, failed, pendingApproval }

class PaymentStatusPage extends StatefulWidget {
  final PaymentStatus status;
  final String? message;
  final bool isAr;
  final VoidCallback? onRetry;

  const PaymentStatusPage({
    super.key,
    required this.status,
    this.message,
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
        color = AppColors.buttonBlueDark;
        lightColor = AppColors.buttonBlueDark.withValues(alpha: 0.1);
        fallbackIcon = Icons.error_outline;
        break;
      case PaymentStatus.pendingApproval:
        title = AppLocalizations.of(context)!.pending_approval;
        description = AppLocalizations.of(context)!.order_received_iban_message;
        color = AppColors.buttonBlueDark;
        lightColor = AppColors.buttonBlueDark.withValues(alpha: 0.1);
        fallbackIcon = Icons.access_time;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.buttonBlueLight,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(32),
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
                                // Title
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Description
                                Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
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
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.status == PaymentStatus.failed &&
                                widget.onRetry != null) ...[
                              _buildPrimaryButton(
                                context,
                                text: AppLocalizations.of(
                                  context,
                                )!.retry_payment,
                                onPressed: widget.onRetry!,
                                color: color,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (widget.status ==
                                PaymentStatus.pendingApproval) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSecondaryButton(
                                      context,
                                      text: AppLocalizations.of(
                                        context,
                                      )!.orders,
                                      onPressed: () {
                                        HomeTab.clearBasket();
                                        HomeScreen.switchTabNotifier.value = 1;
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildPrimaryButton(
                                      context,
                                      text: AppLocalizations.of(
                                        context,
                                      )!.back_to_home,
                                      onPressed: () {
                                        HomeTab.clearBasket();
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _buildSecondaryButton(
                                context,
                                text: AppLocalizations.of(
                                  context,
                                )!.back_to_home,
                                onPressed: () {
                                  if (widget.status == PaymentStatus.success ||
                                      widget.status ==
                                          PaymentStatus.pendingApproval) {
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.buttonBlueDark,
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
