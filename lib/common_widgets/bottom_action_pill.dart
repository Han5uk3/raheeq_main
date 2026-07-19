import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';

class BottomActionPill extends StatelessWidget {
  final Widget titleWidget;
  final Widget? subtitleWidget;
  final String buttonText;
  final VoidCallback onButtonTap;
  final bool isLoading;

  const BottomActionPill({
    super.key,
    required this.titleWidget,
    this.subtitleWidget,
    required this.buttonText,
    required this.onButtonTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(30),
      color: AppColors.buttonBlueDark,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.buttonBlueDark,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (subtitleWidget != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [subtitleWidget!, titleWidget],
              )
            else
              titleWidget,
            ElevatedButton(
              onPressed: isLoading ? null : onButtonTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white,
                foregroundColor: AppColors.buttonBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: isLoading
                  ? const WaterLoadingIndicator(size: 20)
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
