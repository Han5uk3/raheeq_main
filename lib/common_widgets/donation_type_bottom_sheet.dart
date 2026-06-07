import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';

class DonationTypeBottomSheet extends StatefulWidget {
  final VoidCallback onOneTimeSelected;
  final VoidCallback onMonthlySelected;

  const DonationTypeBottomSheet({
    super.key,
    required this.onOneTimeSelected,
    required this.onMonthlySelected,
  });

  @override
  State<DonationTypeBottomSheet> createState() => _DonationTypeBottomSheetState();
}

class _DonationTypeBottomSheetState extends State<DonationTypeBottomSheet> {
  String _selectedType = 'one_time';

  Widget _buildDonationOption({
    required bool isAr,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
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
                  ? const Color(0xFF389BB8)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF389BB8),
                  size: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.buttonBlueDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[500],
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
                  color: const Color(0xFF389BB8),
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.choose_donation_type,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                AppLocalizations.of(context)!.support_once_or_make_a_lasting_impact,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                      onTap: () {
                        setState(() {
                          _selectedType = 'one_time';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDonationOption(
                      isAr: isAr,
                      title: AppLocalizations.of(context)!.monthly,
                      subtitle: AppLocalizations.of(context)!.recurring_impact,
                      icon: Icons.sync,
                      isSelected: _selectedType == 'monthly',
                      onTap: () {
                        setState(() {
                          _selectedType = 'monthly';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    Navigator.pop(context);
                    if (_selectedType == 'one_time') {
                      widget.onOneTimeSelected();
                    } else {
                      widget.onMonthlySelected();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF196482),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continue_btn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
