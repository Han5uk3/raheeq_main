import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'contribution_details_page.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';

class SubscriptionPlanSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;
  final List<OrderCategoryState> orderStates;
  final String? campaignId;

  const SubscriptionPlanSelectionPage({
    super.key,
    required this.checkoutItems,
    required this.orderStates,
    this.campaignId,
  });

  @override
  State<SubscriptionPlanSelectionPage> createState() =>
      _SubscriptionPlanSelectionPageState();
}

class _SubscriptionPlanSelectionPageState
    extends State<SubscriptionPlanSelectionPage> {
  bool _isLoadingPlans = true;
  bool _isCreatingCheckout = false;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selectedPlan;

  // Plan Details State
  DateTime? _startDate;
  DateTime? _endDate;
  int _months = 1;
  final List<int> _selectedDaysOfWeek = []; // 1=Mon, 2=Tue... 7=Sun

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

  void _onContinue(BuildContext context) async {
    if (_selectedPlan == null) return;
    final freq = _selectedPlan!.frequency;
    final Map<String, dynamic> subscriptionPayload = {
      'planId': _selectedPlan!.id,
    };

    if (freq == SubscriptionFrequency.everyDay) {
      if (_startDate == null || _endDate == null) {
        _showError('Please select both start and end dates.');
        return;
      }
      subscriptionPayload['startDate'] = _startDate!.toUtc().toIso8601String();
      subscriptionPayload['endDate'] = _endDate!.toUtc().toIso8601String();
    } else if (freq == SubscriptionFrequency.onceAWeek ||
        freq == SubscriptionFrequency.twiceAWeek) {
      if (_selectedDaysOfWeek.isEmpty) {
        _showError('Please select delivery days.');
        return;
      }
      if (freq == SubscriptionFrequency.onceAWeek &&
          _selectedDaysOfWeek.length != 1) {
        _showError('Please select exactly 1 day for Once A Week plan.');
        return;
      }
      if (freq == SubscriptionFrequency.twiceAWeek &&
          _selectedDaysOfWeek.length != 2) {
        _showError('Please select exactly 2 days for Twice A Week plan.');
        return;
      }
      subscriptionPayload['months'] = _months;
      subscriptionPayload['daysOfWeek'] = _selectedDaysOfWeek;
    } else if (freq == SubscriptionFrequency.monthly) {
      if (_startDate == null) {
        _showError('Please select a start date.');
        return;
      }
      subscriptionPayload['months'] = _months;
      subscriptionPayload['startDate'] = _startDate!.toUtc().toIso8601String();
    } else {
      subscriptionPayload['months'] = _months;
    }

    setState(() {
      _isCreatingCheckout = true;
    });

    try {
      final apiService = ApiService();
      Response response;
      if (widget.campaignId != null) {
        response = await apiService.createCheckoutCampaign(
          campaignId: widget.campaignId!,
          items: widget.checkoutItems,
          subscription: subscriptionPayload,
        );
      } else {
        response = await apiService.createCheckoutQuick(
          items: widget.checkoutItems,
          subscription: subscriptionPayload,
        );
      }

      final checkoutDataMap = response.data['data'];
      final checkoutData = Checkout.fromJson(checkoutDataMap);

      setState(() {
        _isCreatingCheckout = false;
      });

      if (mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributionDetailsPage(
              orderStates: widget.orderStates,
              donationType: isAr
                  ? 'تبرع شهري متكرر'
                  : 'Recurring Donation',
              checkoutData: checkoutData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingCheckout = false;
      });
      _showError('Failed to create checkout. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = DateTime.now().add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? initialDate,
      firstDate: initialDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.buttonBlueDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            _showError('End date cannot be before start date.');
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Widget _buildDatePicker(BuildContext context, bool isAr, bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final label = isStart
        ? (isAr ? 'تاريخ البدء' : 'Start Date')
        : (isAr ? 'تاريخ الانتهاء' : 'End Date');
    return GestureDetector(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : (isAr ? 'اختر التاريخ' : 'Select Date'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.buttonBlueDark,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today,
              color: AppColors.buttonBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'مدة الاشتراك (بالأشهر)' : 'Subscription Duration (Months)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.buttonBlueDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () {
                if (_months > 1) {
                  setState(() {
                    _months--;
                  });
                }
              },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.buttonBlue,
              iconSize: 28,
            ),
            const SizedBox(width: 24),
            Text(
              '$_months',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.buttonBlueDark,
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: () {
                if (_months < 12) {
                  setState(() {
                    _months++;
                  });
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.buttonBlue,
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekSelector(BuildContext context, bool isAr) {
    final days = [
      {'id': 1, 'name': isAr ? 'الاثنين' : 'Mon'},
      {'id': 2, 'name': isAr ? 'الثلاثاء' : 'Tue'},
      {'id': 3, 'name': isAr ? 'الأربعاء' : 'Wed'},
      {'id': 4, 'name': isAr ? 'الخميس' : 'Thu'},
      {'id': 5, 'name': isAr ? 'الجمعة' : 'Fri'},
      {'id': 6, 'name': isAr ? 'السبت' : 'Sat'},
      {'id': 7, 'name': isAr ? 'الأحد' : 'Sun'},
    ];

    final maxAllowed =
        _selectedPlan?.frequency == SubscriptionFrequency.onceAWeek ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr
              ? 'أيام التوصيل (اختر $maxAllowed)'
              : 'Delivery Days (Select $maxAllowed)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.buttonBlueDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((day) {
            final id = day['id'] as int;
            final isSelected = _selectedDaysOfWeek.contains(id);
            return FilterChip(
              label: Text(day['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedDaysOfWeek.length < maxAllowed) {
                      _selectedDaysOfWeek.add(id);
                    } else if (maxAllowed == 1) {
                      _selectedDaysOfWeek.clear();
                      _selectedDaysOfWeek.add(id);
                    }
                  } else {
                    _selectedDaysOfWeek.remove(id);
                  }
                });
              },
              selectedColor: AppColors.buttonBlue.withValues(alpha: 0.2),
              checkmarkColor: AppColors.buttonBlueDark,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.buttonBlueDark : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedPlanDetails(BuildContext context, bool isAr) {
    if (_selectedPlan == null) return const SizedBox.shrink();

    final freq = _selectedPlan!.frequency;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تخصيص الخطة' : 'Customize Plan',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonBlueDark,
            ),
          ),
          const SizedBox(height: 16),
          if (freq == SubscriptionFrequency.everyDay) ...[
            _buildDatePicker(context, isAr, true),
            const SizedBox(height: 12),
            _buildDatePicker(context, isAr, false),
          ] else if (freq == SubscriptionFrequency.onceAWeek ||
              freq == SubscriptionFrequency.twiceAWeek) ...[
            _buildMonthSelector(context, isAr),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDaysOfWeekSelector(context, isAr),
          ] else if (freq == SubscriptionFrequency.monthly) ...[
            _buildMonthSelector(context, isAr),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDatePicker(context, isAr, true),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'خطط الاشتراك' : 'Subscription Plans';
    final subtitle = isAr
        ? 'اختر خطة الاشتراك المناسبة لك'
        : 'Choose a subscription plan';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
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
                child: _isLoadingPlans
                    ? const Center(child: WaterLoadingIndicator())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _plans.isEmpty
                    ? Center(
                        child: Text(
                          isAr
                              ? 'لا توجد خطط متاحة حالياً'
                              : 'No plans available at the moment',
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: 120,
                        ),
                        child: Column(
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
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF0F7FB)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.buttonBlue
                                            : Colors.grey[200]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.buttonBlue
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (plan.image != null &&
                                            plan.image!.isNotEmpty)
                                          CachedNetworkImage(
                                            imageUrl: plan.image!,
                                            width: 30,
                                            height: 30,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                const SizedBox(
                                                  width: 30,
                                                  height: 30,
                                                  child: Center(
                                                    child:
                                                        WaterLoadingIndicator(
                                                          size: 20,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
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
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                plan.localizedDescription(isAr),
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
                                            color: AppColors.buttonBlue,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildSelectedPlanDetails(context, isAr),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          if (!_isLoadingPlans && _plans.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedPlan == null || _isCreatingCheckout)
                      ? null
                      : () => _onContinue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isCreatingCheckout
                      ? const WaterLoadingIndicator(
                          size: 24,
                          waveColor1: Colors.white,
                          waveColor2: Colors.white,
                        )
                      : Text(
                          isAr ? 'متابعة' : 'Continue',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
