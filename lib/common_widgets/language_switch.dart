import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
        child: CachedNetworkImage(
          imageUrl: isArabic
              ? "https://flagcdn.com/w80/sa.png"
              : "https://flagcdn.com/w80/us.png",
          imageBuilder: (context, imageProvider) => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => const SizedBox(
            width: 34,
            height: 34,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: WaterLoadingIndicator(size: 30),
            ),
          ),
          errorWidget: (context, url, error) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              isArabic ? '🇸🇦' : '🇺🇸',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
