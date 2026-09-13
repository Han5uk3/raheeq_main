import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:shimmer/shimmer.dart';

import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/subscription_status_badge.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/models/subscription_model.dart';
import 'package:raheeq_main/pages/home/pages/subscription_details_page.dart';
import 'package:raheeq_main/utils/formatters.dart';

class RecurringDonationsPage extends StatefulWidget {
  const RecurringDonationsPage({super.key});

  @override
  State<RecurringDonationsPage> createState() => _RecurringDonationsPageState();
}

class _RecurringDonationsPageState extends State<RecurringDonationsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubscriptionModel> _subscriptions = [];

  /// Shown while the API still omits `completedCount` / `totalCount`, so the
  /// card reads as a progress bar rather than an empty track. Drop these once
  /// the endpoint returns both fields.
  static const int _fallbackCompletedCount = 1;
  static const int _fallbackTotalCount = 7;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getMySubscriptions();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data']['items'] as List;
        final subscriptions = data
            .map((json) => SubscriptionModel.fromJson(json))
            .toList();

        subscriptions.sort((a, b) => b.startDate.compareTo(a.startDate));

        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Failed to load subscriptions';
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('connection error')) {
        errorMessage = AppLocalizations.of(context)!.internet_error;
      } else if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      } else {
        errorMessage = AppLocalizations.of(context)!.error;
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.recurring_donations;
    final subtitle = AppLocalizations.of(context)!.manage_your_subscriptions;

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
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark,
                border: Border.all(color: AppColors.buttonBlueDark, width: 0),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(style: BorderStyle.none, width: 0),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _buildContent(isAr),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Container(
        key: const ValueKey('error'),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.error_occurred_try_again,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchSubscriptions,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.no_active_subscriptions,
              style: TextStyle(
                color: AppColors.headersubtitlecolor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                HomeScreen.switchTabNotifier.value = 0;
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.order_now,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: Colors.white,
      key: const ValueKey('content'),
      onRefresh: _fetchSubscriptions,
      color: AppColors.buttonBlueDark,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          return _buildSubscriptionCard(subscription, isAr);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionModel subscription, bool isAr) {
    final planName = isAr ? subscription.planNameAr : subscription.planName;

    return GestureDetector(
      onTap: () {
        subscription.status != "CANCELLED"
            ? Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SubscriptionDetailsPage(subscriptionId: subscription.id),
                ),
              )
            : Null;
      },
      child: Material(
        elevation: 2,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner (now white background)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      textDirection: TextDirection.ltr,
                      "#${subscription.subscriptionNumber}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),

                    SubscriptionStatusBadge(status: subscription.status),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
                indent: 8,
                endIndent: 8,
              ),
              // Card Body
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: subscription.planImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          planName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(height: 1, color: Colors.grey.shade300),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.start_date,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.expires_on,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Deliveries completed out of the total for the plan.
                    _buildProgressBar(subscription, isAr),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.buttonBlueDark.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            Formatters.formatDate(
                              context,
                              subscription.startDate,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.buttonBlueDark.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            Formatters.formatDate(
                              context,
                              subscription.endDate,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress through the subscription's deliveries.
  ///
  /// Fills from the left in English and from the right in Arabic, so the bar
  /// always grows away from the start date shown beneath it.
  Widget _buildProgressBar(SubscriptionModel subscription, bool isAr) {
    // A missing `totalCount` means the API has not been updated yet; the two
    // counts arrive together, so fall back to the pair rather than to a
    // separate default per field, which would report 1 completed delivery on a
    // subscription the API says has none.
    final bool hasCounts = subscription.totalCount > 0;
    final int total = hasCounts ? subscription.totalCount : _fallbackTotalCount;
    final int completed = hasCounts
        ? subscription.completedCount.clamp(0, total)
        : _fallbackCompletedCount;

    return Container(
      width: double.infinity,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.buttonBlueDark.withAlpha(30),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Align(
        alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: completed / total,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.buttonBlueDark,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
    );
  }

  String _localizeFrequency(String frequency) {
    final freq = frequency.toLowerCase().trim();
    if (freq == 'everyday') {
      return AppLocalizations.of(context)!.everyday;
    } else if (freq == 'once_a_week') {
      return AppLocalizations.of(context)!.once_a_week;
    } else if (freq == 'once_a_month') {
      return AppLocalizations.of(context)!.once_a_month;
    } else if (freq == "twice_a_week") {
      return AppLocalizations.of(context)!.twice_a_week;
    } else if (freq == 'custom') {
      return AppLocalizations.of(context)!.custom;
    }
    return frequency;
  }

  /// Height of one line of text at [fontSize], measured with the font, locale
  /// and text scale the loaded card will use.
  ///
  /// Arabic resolves to a taller fallback face than the Latin one — 19px to 17
  /// at a font size of 12 — so a bar with a hardcoded height leaves the
  /// skeleton and the loaded card at different heights in one locale or the
  /// other, and the list shifts as it loads.
  double _lineHeight(double fontSize) {
    // Two words, because a space splits the line into runs and pulls in the
    // Arabic face the labels on these cards actually render in.
    final sample = Localizations.localeOf(context).languageCode == 'ar'
        ? 'نص عربي'
        : 'Text';
    final painter = TextPainter(
      text: TextSpan(
        text: sample,
        // The style a card's Text resolves to: Material hands its subtree
        // bodyMedium, which carries the theme's font family and fallbacks.
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(fontSize: fontSize),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      // The locale picks the font fallback, the same way a Text does.
      locale: Localizations.maybeLocaleOf(context),
      textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
      maxLines: 1,
    )..layout();

    return painter.height;
  }

  /// One placeholder shape.
  ///
  /// Painted white because [Shimmer] masks its subtree with [BlendMode.srcIn]:
  /// only what the skeleton paints picks up the sweep, so the card itself has
  /// to stay outside the shimmer to keep its white fill and elevation.
  Widget _skeletonBox({
    double? width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// A bar standing in for a line of text, sized to the line it replaces.
  Widget _skeletonTextBar({required double width, required double fontSize}) {
    return _skeletonBox(width: width, height: _lineHeight(fontSize));
  }

  /// Mirrors [_buildSubscriptionCard]: number and status pill over the plan
  /// image and name, then the date labels, progress bar and date chips.
  Widget _buildShimmerCard() {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _skeletonTextBar(width: 96, fontSize: 14),
                  // The pill wraps its label in 6px of vertical padding.
                  _skeletonBox(
                    width: 88,
                    height: _lineHeight(12) + 12,
                    radius: 10,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 8,
              endIndent: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _skeletonBox(width: 40, height: 40, radius: 8),
                      const SizedBox(width: 8),
                      _skeletonTextBar(width: 140, fontSize: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _skeletonTextBar(width: 70, fontSize: 12),
                      _skeletonTextBar(width: 70, fontSize: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _skeletonBox(width: double.infinity, height: 10, radius: 100),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date chips pad their label by 4px top and bottom.
                      _skeletonBox(
                        width: 76,
                        height: _lineHeight(10) + 8,
                        radius: 8,
                      ),
                      _skeletonBox(
                        width: 76,
                        height: _lineHeight(10) + 8,
                        radius: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      key: const ValueKey('loader'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }
}
