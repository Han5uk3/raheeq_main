import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/pages/home/pages/suggestions_page.dart';
import 'package:raheeq_main/pages/home/pages/complaints_page.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  bool _isNavigating = false;

  Future<void> _handleTap(
    BuildContext context,
    VoidCallback action, {
    bool showLoader = false,
  }) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    if (showLoader) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder: (context) => Center(
          child: Container(
            height: 100,
            width: 100,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: WaterLoadingIndicator(size: 20),
          ),
        ),
      );
      // Give the loader a brief moment to render before executing heavy intent
      await Future.delayed(const Duration(milliseconds: 200));
    }

    action();

    // Wait for external navigation (like Freshchat SDK) to take over
    await Future.delayed(const Duration(seconds: 1));

    if (mounted && showLoader) {
      Navigator.pop(context); // Dismiss loader
    }

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final title = loc.contact_us;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    _buildCard(
                      context: context,
                      title: loc.suggestions,
                      description: loc.your_suggestions_hint,
                      icon: Icons.lightbulb_outline,
                      onTap: () {
                        _handleTap(context, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SuggestionsPage(),
                            ),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context: context,
                      title: loc.contact_us,
                      description: loc.contact_us_desc,
                      icon: Icons.chat_bubble_outline,
                      onTap: () {
                        _handleTap(context, () {
                          Freshchat.showConversations(
                            tags: const ["chat_with_us"],
                            filteredViewTitle: "Rahiq Support",
                          );
                        }, showLoader: true);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context: context,
                      title: loc.complaints,
                      description: loc.complaints_desc,
                      icon: Icons.report_problem_outlined,
                      onTap: () {
                        _handleTap(context, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ComplaintsPage(),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEAEFF2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.buttonBlueDark, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
