import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/authentication/login.dart';
import '../../utils/colors.dart';
import '../../common_widgets/language_switch.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _onboardingImages = [
    'assets/onboarding/onboard1.png',
    'assets/onboarding/onboard2.png',
    'assets/onboarding/onboard3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3 line indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: List.generate(3, (index) {
                  final isSelected = _currentPage == index;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.indicatorBlue
                            : AppColors.indicatorGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Header: Skip button & Language Switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LanguageSwitchButton(),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _currentPage == 2 ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: _currentPage == 2,
                      child: TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuart,
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.skip,
                          style: const TextStyle(
                            color: AppColors.buttonBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingImages.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 0.0;
                      if (_pageController.position.haveDimensions) {
                        value = index - (_pageController.page ?? 0);
                      } else {
                        // Handle initial state before dimensions are available
                        value = (index - _currentPage).toDouble();
                      }
                      return _buildPage(index, value);
                    },
                  );
                },
              ),
            ),

            // Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 400),
                    crossFadeState: _currentPage < 2
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.continue_btn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    secondChild: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.start_donating,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == 2) ...[
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _currentPage == 2 ? 1 : 0,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: AppLocalizations.of(
                            context,
                          )!.terms_agree_prefix,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: AppLocalizations.of(
                                context,
                              )!.terms_conditions,
                              style: const TextStyle(
                                color: AppColors.buttonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Link to Terms & Conditions
                                },
                            ),
                            TextSpan(text: AppLocalizations.of(context)!.and),
                            TextSpan(
                              text: AppLocalizations.of(
                                context,
                              )!.privacy_policy,
                              style: const TextStyle(
                                color: AppColors.buttonBlue,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Link to Privacy Policy
                                },
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index, double value) {
    // pageOffset is how far the page is from the center (0.0 means centered)
    double opacity = (1 - value.abs()).clamp(0.0, 1.0);
    double scale = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
    double horizontalOffset = value * 100; // Parallax effect
    double verticalOffset = value.abs() * 50; // Slide up from transparency

    final l10n = AppLocalizations.of(context)!;
    String title = '';
    String subtitle = '';

    if (index == 0) {
      title = l10n.onboard1_title;
      subtitle = l10n.onboard1_subtitle;
    } else if (index == 1) {
      title = l10n.onboard2_title;
      subtitle = l10n.onboard2_subtitle;
    } else if (index == 2) {
      title = l10n.onboard3_title;
      subtitle = l10n.onboard3_subtitle;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image with Parallax & Scale
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..translateByDouble(horizontalOffset, 0.0, 0.0, 1.0)
                ..scaleByDouble(scale, scale, 1.0, 1.0),
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  _onboardingImages[index],
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Text elements with Slide & Fade
        Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
