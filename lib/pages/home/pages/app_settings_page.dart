import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/main.dart';
import 'package:raheeq_main/utils/colors.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  // bool _isDarkMode = false;
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
    final title = AppLocalizations.of(context)!.app_settings;
    final subtitle = AppLocalizations.of(
      context,
    )!.manage_preferences_and_app_info;

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
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Switch
                      GestureDetector(
                        onTap: () {
                          _showLanguageDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEAEFF2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.language,
                                    color: AppColors.buttonBlue,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    AppLocalizations.of(context)!.app_language,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    isAr ? 'عربي' : 'English',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.buttonBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dark Mode Switch
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 16,
                      //     vertical: 12,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFFF2F4F5),
                      //     borderRadius: BorderRadius.circular(16),
                      //   ),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Row(
                      //         children: [
                      //           Icon(
                      //             _isDarkMode
                      //                 ? Icons.dark_mode
                      //                 : Icons.light_mode,
                      //             color: AppColors.buttonBlue,
                      //           ),
                      //           const SizedBox(width: 16),
                      //           Text(
                      //             AppLocalizations.of(context)!.dark_mode,
                      //             style: const TextStyle(
                      //               fontSize: 16,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //       Switch(
                      //         value: _isDarkMode,
                      //         onChanged: (value) {
                      //           setState(() {
                      //             _isDarkMode = value;
                      //           });
                      //           CustomSnackbar.show(context: context, message: //                 AppLocalizations.of(context)!.theme_switching_coming_soon,
                      //, duration: const Duration(seconds: 1));
                      //         },
                      //         activeThumbColor: AppColors.buttonBlueDark,
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 24),

                      // App Info Card
                      Text(
                        AppLocalizations.of(context)!.app_information,
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
                              color: Colors.grey.withValues(alpha: 0.2),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              AppLocalizations.of(context)!.version,
                              _appVersion.isEmpty ? '...' : _appVersion,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFEAEFF2),
                              ),
                            ),
                            _buildInfoRow(
                              AppLocalizations.of(context)!.build_number,
                              _buildNumber.isEmpty ? '...' : _buildNumber,
                            ),
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentLocale = Localizations.localeOf(context);
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.app_language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.black, size: 24),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                _buildLanguageOption(
                  context: context,
                  title: 'English',
                  localeCode: 'en',
                  currentLocaleCode: currentLocale.languageCode,
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  context: context,
                  title: 'عربي',
                  localeCode: 'ar',
                  currentLocaleCode: currentLocale.languageCode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String localeCode,
    required String currentLocaleCode,
  }) {
    final isSelected = currentLocaleCode == localeCode;
    return GestureDetector(
      onTap: () async {
        localeNotifier.value = Locale(localeCode);
        await AppStorage.saveLocale(localeCode);
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonBlue : const Color(0xFFEAEFF2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.buttonBlue : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.radio_button_checked,
                color: AppColors.buttonBlue,
                size: 20,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Color(0xFFEAEFF2),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: AppColors.headersubtitlecolor),
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
