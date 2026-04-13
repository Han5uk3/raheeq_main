import 'package:flutter/material.dart';
import '../main.dart';

class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          localeNotifier.value = isArabic 
              ? const Locale('en') 
              : const Locale('ar');
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            isArabic ? '🇸🇦' : '🇺🇸',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
