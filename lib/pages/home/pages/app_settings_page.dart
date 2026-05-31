import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _isDarkMode = false;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'إعدادات التطبيق' : 'App Settings';
    final subtitle = isAr ? 'إدارة التفضيلات ومعلومات التطبيق' : 'Manage preferences and app info';

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dark Mode Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                  color: AppColors.buttonBlue,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  isAr ? 'الوضع الداكن' : 'Dark Mode',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isDarkMode,
                              onChanged: (value) {
                                setState(() {
                                  _isDarkMode = value;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تبديل السمة قريباً' : 'Theme switching coming soon'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              activeColor: AppColors.buttonBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App Info Card
                      Text(
                        isAr ? 'معلومات التطبيق' : 'App Information',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEAEFF2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(isAr ? 'الإصدار' : 'Version', _appVersion.isEmpty ? '...' : _appVersion),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFEAEFF2)),
                            ),
                            _buildInfoRow(isAr ? 'رقم البناء' : 'Build Number', _buildNumber.isEmpty ? '...' : _buildNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.headersubtitlecolor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
