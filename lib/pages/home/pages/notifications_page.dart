import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'الإشعارات' : 'Notifications';
    final subtitle = isAr ? 'آخر التحديثات والتنبيهات' : 'Latest updates and alerts';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: const Color(0x4D91E3FE),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "No new notifications",
                    style: TextStyle(
                      color: AppColors.headersubtitlecolor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
