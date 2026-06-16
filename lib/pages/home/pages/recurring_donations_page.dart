import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/api/apis.dart';
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
        _errorMessage = 'An error occurred while loading subscriptions.';
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
                child: _buildContent(isAr),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: WaterLoadingIndicator(size: 30),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _fetchSubscriptions,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
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
      onRefresh: _fetchSubscriptions,
      color: AppColors.buttonBlue,
      child: ListView.separated(
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SubscriptionDetailsPage(subscriptionId: subscription.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subscription.planImage.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    subscription.planImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? subscription.planNameAr : subscription.planName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          subscription.frequency,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          subscription.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subscription.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(subscription.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
