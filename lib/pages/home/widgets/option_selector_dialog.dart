import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
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
    final textDirection = Directionality.of(context);

    final mostNeedyLabel = isAr ? 'الأكثر احتياجاً' : 'Most needy';
    final specificLabel = isAr ? 'تحديد' : 'Specific';
    final titleText = isAr ? 'اختر نوع التبرع' : 'Choose donation type';
    final continueText = isAr ? 'متابعة' : 'Continue';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.black),
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
            const SizedBox(height: 24),

            if (widget.showClearOption) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedOption == null
                          ? null
                          : () {
                              Navigator.of(context).pop(_selectedOption);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        continueText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _selectedOption == null
                    ? null
                    : () {
                        Navigator.of(context).pop(_selectedOption);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  continueText,
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
        setState(() {
          _selectedOption = id;
        });
      },
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
                  textAlign: TextAlign.center,
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
}
