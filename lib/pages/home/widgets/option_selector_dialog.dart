import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class OptionSelectorDialog extends StatefulWidget {
  final String title;
  final bool showClearOption;

  const OptionSelectorDialog({
    Key? key,
    required this.title,
    this.showClearOption = false,
  }) : super(key: key);

  @override
  State<OptionSelectorDialog> createState() => _OptionSelectorDialogState();
}

class _OptionSelectorDialogState extends State<OptionSelectorDialog> {
  String? _selectedOption;

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
                    title: '$mostNeedyLabel\n${widget.title}',
                    icon: Icons.volunteer_activism_outlined,
                    isSelected: _selectedOption == 'most_in_need',
                    textDirection: textDirection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGridCard(
                    id: 'specific',
                    title: '$specificLabel\n${widget.title}',
                    icon: Icons.mosque_outlined,
                    isSelected: _selectedOption == 'specific',
                    textDirection: textDirection,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (widget.showClearOption) ...[
              const SizedBox(height: 12),
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
                  isAr ? 'إزالة التحديد' : 'Clear Selection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String id,
    required String title,
    required IconData icon,
    required bool isSelected,
    required TextDirection textDirection,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = id;
        });
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? AppColors.buttonBlueDark
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.buttonBlueDark
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned.directional(
                textDirection: textDirection,
                top: 8,
                end: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
