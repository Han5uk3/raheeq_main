import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';

class SubscriptionPlansBottomSheet extends StatefulWidget {
  final ValueChanged<SubscriptionPlan> onPlanSelected;
  final VoidCallback? onBack;

  const SubscriptionPlansBottomSheet({
    super.key,
    required this.onPlanSelected,
    this.onBack,
  });

  @override
  State<SubscriptionPlansBottomSheet> createState() =>
      _SubscriptionPlansBottomSheetState();
}

String _frequencyLabel(BuildContext context, SubscriptionFrequency frequency) {
  final l10n = AppLocalizations.of(context)!;
  switch (frequency) {
    case SubscriptionFrequency.everyDay:
      return l10n.everyday;
    case SubscriptionFrequency.onceAWeek:
      return l10n.once_a_week;
    case SubscriptionFrequency.twiceAWeek:
      return l10n.twice_a_week;
    case SubscriptionFrequency.monthly:
      return l10n.once_a_month;
    case SubscriptionFrequency.unknown:
      return l10n.custom;
  }
}

class _SubscriptionPlansBottomSheetState
    extends State<SubscriptionPlansBottomSheet> {
  bool _isLoadingPlans = true;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final api = ApiService();
      final response = await api.getSubscriptionPlans();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        setState(() {
          _plans = data
              .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoadingPlans = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load subscription plans';
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching plans: $e';
        _isLoadingPlans = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                      Navigator.pop(context);
                      if (widget.onBack != null) {
                        widget.onBack!();
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        backArrowIcon(context),
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.subscription_plans,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.choose_a_subscription_plan,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoadingPlans)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    top: 0,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (_plans.isEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.no_plans_available_at_the_moment,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          final isSelected = _selectedPlan?.id == plan.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlan = plan;
                              });
                              FocusManager.instance.primaryFocus?.unfocus();
                              SystemChannels.textInput.invokeMethod(
                                'TextInput.hide',
                              );
                              Navigator.pop(context);
                              widget.onPlanSelected(plan);
                            },
                            child: Material(
                              color: Colors.white,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0F7FB)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.buttonBlueDark
                                        : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (plan.image != null &&
                                        plan.image!.isNotEmpty)
                                      CachedNetworkImage(
                                        imageUrl: plan.image!,
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const SizedBox(
                                              width: 80,
                                              height: 80,
                                            ),
                                      )
                                    else
                                      const SizedBox(width: 80, height: 80),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan.localizedName(isAr),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.buttonBlueDark,
                                              height: 1.2,
                                            ),
                                          ),
                                    
                                          const SizedBox(height: 4),
                                          Text(
                                            _frequencyLabel(
                                              context,
                                              plan.frequency,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.buttonBlueDark,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
