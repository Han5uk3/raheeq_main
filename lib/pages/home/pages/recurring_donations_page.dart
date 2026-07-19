import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/api/new.dart';
import 'package:shimmer/shimmer.dart';

import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/models/subscription_model.dart';
import 'package:raheeq_main/pages/home/pages/subscription_details_page.dart';

class RecurringDonationsPage extends StatefulWidget {
  const RecurringDonationsPage({super.key});

  @override
  State<RecurringDonationsPage> createState() => _RecurringDonationsPageState();
}

class _RecurringDonationsPageState extends State<RecurringDonationsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SubscriptionModel> _subscriptions = [];

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
      setState(() {
        _errorMessage = e.toString();
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
      key: const ValueKey('content'),
      onRefresh: _fetchSubscriptions,
      color: AppColors.buttonBlueDark,
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
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
    final bool isActive = subscription.status.toLowerCase() == 'active';
    final bool isCancelled = subscription.status.toLowerCase() == 'cancelled';
    final Color statusColor = isActive
        ? Colors.green
        : isCancelled
        ? Colors.red
        : AppColors.buttonBlueDark;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _localizeStatus(subscription.status, context),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${AppLocalizations.of(context)!.since}${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(subscription.startDate)}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      textDirection: TextDirection.ltr,
                      "#${subscription.subscriptionNumber}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location (Target Name)
                    const SizedBox(height: 12),

                    // Package Details Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizeFrequency(subscription.frequency),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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

  String _localizeStatus(String status, BuildContext context) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'active') {
      return AppLocalizations.of(context)!.status_active;
    }
    if (lowerStatus == 'cancelled') {
      return AppLocalizations.of(context)!.status_cancelled;
    }
    if (lowerStatus == 'expired') {
      return AppLocalizations.of(context)!.status_expired;
    }
    if (lowerStatus == 'pending') {
      return AppLocalizations.of(context)!.status_pending;
    }
    if (lowerStatus == 'completed') {
      return AppLocalizations.of(context)!.status_completed;
    }

    return status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1).toLowerCase()
        : '';
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 60, height: 16, color: Colors.white),
                        ],
                      ),
                      Container(width: 80, height: 14, color: Colors.white),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 20, color: Colors.white),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
