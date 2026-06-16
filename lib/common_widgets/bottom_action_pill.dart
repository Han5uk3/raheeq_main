import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';

class BottomActionPill extends StatelessWidget {
  final Widget titleWidget;
  final Widget? subtitleWidget;
  final String buttonText;
  final VoidCallback onButtonTap;

  const BottomActionPill({
    super.key,
    required this.titleWidget,
    this.subtitleWidget,
    required this.buttonText,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.buttonBlueDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
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
            onPressed: onButtonTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.buttonBlueDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
