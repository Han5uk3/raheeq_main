import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';
import 'package:raheeq_main/utils/colors.dart';

enum PaymentStatus { success, failed, pendingApproval }

class PaymentStatusPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    String lottieUrl = '';
    String title = '';
    String description = '';
    Color color = AppColors.buttonBlueDark;

    switch (status) {
      case PaymentStatus.success:
        lottieUrl =
            'https://lottie.host/b02cb06a-a827-4a7b-a2eb-45de4e0bf31c/zZ7Z7Z7Z7Z.json'; // Public success animation
        title = isAr ? 'تم الدفع بنجاح!' : 'Payment Successful!';
        description = isAr
            ? 'شكراً لتبرعك. جعله الله في ميزان حسناتك.'
            : 'Thank you for your donation.';
        color = Colors.green;
        break;
      case PaymentStatus.failed:
        lottieUrl =
            'https://lottie.host/8cd58752-dfaf-426c-a496-c146e4941d3b/zZ7Z7Z7Z7Z.json'; // Public failed animation
        title = isAr ? 'فشلت عملية الدفع' : 'Payment Failed';
        description =
            message ??
            (isAr
                ? 'حدث خطأ أثناء معالجة الدفع.'
                : 'An error occurred while processing the payment.');
        color = Colors.red;
        break;
      case PaymentStatus.pendingApproval:
        lottieUrl =
            'https://lottie.host/b02cb06a-a827-4a7b-a2eb-45de4e0bf31c/zZ7Z7Z7Z7Z.json'; // Reusing success for pending
        title = isAr ? 'قيد المراجعة' : 'Pending Approval';
        description = isAr
            ? 'تم استلام طلب التحويل البنكي وهو قيد المراجعة.'
            : 'Bank transfer receipt received. Awaiting admin approval.';
        color = Colors.orange;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Fallback to Icon if network fails
              Lottie.network(
                lottieUrl,
                height: 200,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    status == PaymentStatus.failed
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 150,
                    color: color,
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(),
              if (status == PaymentStatus.failed && onRetry != null) ...[
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.buttonBlueDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.buttonBlueDark,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAr ? 'إعادة المحاولة' : 'Retry Payment',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: () {
                  if (status == PaymentStatus.success ||
                      status == PaymentStatus.pendingApproval) {
                    HomeTab.clearBasket();
                  }
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isAr ? 'العودة للرئيسية' : 'Back to Home',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
