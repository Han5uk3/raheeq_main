import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import '../../../utils/colors.dart';

class OptionSelectorDialog extends StatefulWidget {
  final String title;
  final bool showClearOption;
  final String? initialOption;

  const OptionSelectorDialog({
    super.key,
    required this.title,
    this.showClearOption = false,
    this.initialOption,
  });

  @override
  State<OptionSelectorDialog> createState() => _OptionSelectorDialogState();
}

class _OptionSelectorDialogState extends State<OptionSelectorDialog> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final mostNeedyLabel = AppLocalizations.of(context)!.most_needy;
    final specificLabel = AppLocalizations.of(context)!.specific_donation;
    final titleText = AppLocalizations.of(context)!.choose_donation_type;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      backArrowIcon(context),
                      size: 22,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.start,
                    titleText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGridCard(
                    id: 'most_in_need',
                    title: mostNeedyLabel,
                    subtitle: widget.title,
                    icon: Icons.volunteer_activism_outlined,
                    isSelected: _selectedOption == 'most_in_need',
                    isAr: isAr,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGridCard(
                    id: 'specific',
                    title: specificLabel,
                    subtitle: widget.title,
                    icon: Icons.mosque_outlined,
                    isSelected: _selectedOption == 'specific',
                    isAr: isAr,
                  ),
                ),
              ],
            ),
            if (widget.showClearOption) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop('clear');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.clear_all,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isAr,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(id);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.buttonBlueDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.buttonBlueDark,
                    size: 36,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.buttonBlueDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
}
