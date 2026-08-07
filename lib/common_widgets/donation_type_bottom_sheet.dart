import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';

class DonationTypeBottomSheet extends StatefulWidget {
  final Future<void> Function() onOneTimeSelected;
  final VoidCallback onMonthlySelected;

  const DonationTypeBottomSheet({
    super.key,
    required this.onOneTimeSelected,
    required this.onMonthlySelected,
  });

  @override
  State<DonationTypeBottomSheet> createState() =>
      _DonationTypeBottomSheetState();
}

class _DonationTypeBottomSheetState extends State<DonationTypeBottomSheet> {
  String _selectedType = "";
  bool _isProcessingOneTime = false;

  Widget _buildDonationOption({
    required bool isAr,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.buttonBlueDark
                  : AppColors.buttonBlueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 92,
                    child: Center(
                      child: WaterLoadingIndicator(
                        size: 28,
                        waveColor1: Colors.white,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : AppColors.buttonBlueDark,
                        size: 36,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.buttonBlueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
          if (isSelected)
            Positioned(
              top: -8,
              right: isAr ? null : -8,
              left: isAr ? -8 : null,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _isProcessingOneTime
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          SystemChannels.textInput.invokeMethod(
                            'TextInput.hide',
                          );
                          Navigator.pop(context);
                        },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: Icon(
                      backArrowIcon(context),
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.choose_donation_type_108,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      Text(
                        AppLocalizations.of(
                          context,
                        )!.support_once_or_make_a_lasting_impact,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildDonationOption(
                    isAr: isAr,
                    title: AppLocalizations.of(context)!.one_time,
                    subtitle: AppLocalizations.of(context)!.single_donation,
                    icon: Icons.calendar_today_outlined,
                    isSelected: _selectedType == 'one_time',
                    isLoading: _isProcessingOneTime,
                    onTap: _isProcessingOneTime
                        ? () {}
                        : () async {
                            setState(() {
                              _selectedType = 'one_time';
                              _isProcessingOneTime = true;
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                            SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                            // The sheet is kept open (not popped) while the
                            // checkout is created, so it stays on the
                            // navigator stack and reappears if the user
                            // navigates back from the contribution details
                            // page, matching the subscription flow.
                            try {
                              await widget.onOneTimeSelected();
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isProcessingOneTime = false;
                                });
                              }
                            }
                          },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDonationOption(
                    isAr: isAr,
                    title: AppLocalizations.of(context)!.subscription,
                    subtitle: AppLocalizations.of(context)!.recurring_donation,
                    icon: Icons.sync,
                    isSelected: _selectedType == 'monthly',
                    onTap: _isProcessingOneTime
                        ? () {}
                        : () {
                            setState(() {
                              _selectedType = 'monthly';
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                            SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                            Navigator.pop(context);
                            widget.onMonthlySelected();
                          },
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
