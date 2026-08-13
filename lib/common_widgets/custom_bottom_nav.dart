import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';

class CustomBottomNavItem {
  final IconData icon;
  final String label;

  /// Unread count drawn on the icon's top-outer corner. Zero draws nothing.
  final int badgeCount;

  CustomBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomBottomNavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      child: Material(
        elevation: 10,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(45),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(45),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                                colors: [
                                  Color(0xFF1A6A8F),
                                  Color(0xFF1D6F94),
                                  Color(0xFF217498),
                                  Color(0xFF24799D),
                                  Color(0xFF277EA2),
                                  Color(0xFF2A83A6),
                                  Color(0xFF2E89AB),
                                  Color(0xFF318EB0),
                                  Color(0xFF3493B5),
                                  Color(0xFF3798BA),
                                  Color(0xFF3B9EBE),
                                ],
                                stops: [
                                  0.0,
                                  0.0714,
                                  0.1429,
                                  0.2143,
                                  0.2857,
                                  0.5,
                                  0.7143,
                                  0.7857,
                                  0.8571,
                                  0.9286,
                                  1.0,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.buttonBlueDark.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 3,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.grey[400],
                            size: 24,
                          ),
                          // PositionedDirectional resolves `end` against the
                          // ambient direction, so the badge sits on the icon's
                          // top-right in English and its top-left in Arabic.
                          if (item.badgeCount > 0)
                            PositionedDirectional(
                              top: -6,
                              end: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  // Rounded rather than a circle so a
                                  // three-character count widens into a pill
                                  // instead of squashing into an ellipse.
                                  borderRadius: BorderRadius.circular(20),
                                  // Keeps the badge legible against both the
                                  // white bar and the selected tab's gradient.
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  item.badgeCount > 99
                                      ? '99+'
                                      : '${item.badgeCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize:
                            Directionality.of(context) == TextDirection.rtl
                            ? 13
                            : 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.buttonBlueDark
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
