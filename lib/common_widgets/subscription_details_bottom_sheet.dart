import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/subscription_plan.dart';
import 'package:raheeq_main/pages/order/contribution_details_page.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class SubscriptionDetailsBottomSheet extends StatefulWidget {
  final SubscriptionPlan plan;
  final List<Map<String, dynamic>> checkoutItems;
  final List<OrderCategoryState> orderStates;
  final String? campaignId;
  final VoidCallback? onBack;

  const SubscriptionDetailsBottomSheet({
    super.key,
    required this.plan,
    required this.checkoutItems,
    required this.orderStates,
    this.campaignId,
    this.onBack,
  });

  @override
  State<SubscriptionDetailsBottomSheet> createState() =>
      _SubscriptionDetailsBottomSheetState();
}

class _SubscriptionDetailsBottomSheetState
    extends State<SubscriptionDetailsBottomSheet> {
  bool _isCreatingCheckout = false;

  DateTime? _startDate;
  DateTime? _endDate;
  int _months = 1;
  final List<int> _selectedDaysOfWeek = []; // 1=Mon, 2=Tue... 7=Sun

  void _onContinue(BuildContext context) async {
    final freq = widget.plan.frequency;
    final Map<String, dynamic> subscriptionPayload = {'planId': widget.plan.id};

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
        Navigator.pop(context); // Close the bottom sheet
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContributionDetailsPage(
              orderStates: widget.orderStates,
              donationType: AppLocalizations.of(context)!.recurring_donation,
              checkoutData: checkoutData,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingCheckout = false;
      });
      if (e is DioException) {
        _showError("${e.message}");
      }
    }
  }

  void _showError(String message) {
    CustomSnackbar.show(context: context, message: message);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = DateTime.now().add(const Duration(days: 1));

    DateTime firstDate = initialDate;
    if (!isStart && _startDate != null) {
      firstDate = _startDate!.add(const Duration(days: 1));
    }

    DateTime initialPickerDate = (isStart ? _startDate : _endDate) ?? firstDate;
    if (initialPickerDate.isBefore(firstDate)) {
      initialPickerDate = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: firstDate,
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
        ? (AppLocalizations.of(context)!.start_date)
        : (AppLocalizations.of(context)!.end_date);
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
                      : (AppLocalizations.of(context)!.select_date),
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
              color: AppColors.buttonBlueDark,
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
          AppLocalizations.of(context)!.subscription_duration_months,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.buttonBlueDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _months > 1 ? 1.0 : 0.45,
                child: GestureDetector(
                  onTap: () {
                    if (_months > 1) {
                      setState(() {
                        _months -= 1;
                      });
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _months > 1
                          ? AppColors.buttonBlueDark
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 20,
                child: Text(
                  "$_months",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonBlueDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _months < 12 ? 1.0 : 0.45,
                child: GestureDetector(
                  onTap: () {
                    if (_months < 12) {
                      setState(() {
                        _months += 1;
                      });
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _months < 12
                          ? AppColors.buttonBlueDark
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeekSelector(BuildContext context, bool isAr) {
    final days = [
      {'id': 0, 'name': AppLocalizations.of(context)!.sun},
      {'id': 1, 'name': AppLocalizations.of(context)!.mon},
      {'id': 2, 'name': AppLocalizations.of(context)!.tue},
      {'id': 3, 'name': AppLocalizations.of(context)!.wed},
      {'id': 4, 'name': AppLocalizations.of(context)!.thu},
      {'id': 5, 'name': AppLocalizations.of(context)!.fri},
      {'id': 6, 'name': AppLocalizations.of(context)!.sat},
    ];

    final maxAllowed = widget.plan.frequency == SubscriptionFrequency.onceAWeek
        ? 1
        : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.delivery_days_select_maxallowed
              .replaceAll(r'$maxAllowed', maxAllowed.toString()),
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
              selectedColor: AppColors.buttonBlueDark,
              backgroundColor: Colors.white,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final freq = widget.plan.frequency;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
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
                          AppLocalizations.of(context)!.customize_plan,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.plan.localizedName(isAr),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.buttonBlueDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreatingCheckout
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          SystemChannels.textInput.invokeMethod(
                            'TextInput.hide',
                          );
                          _onContinue(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    disabledBackgroundColor: AppColors.buttonBlueDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isCreatingCheckout
                      ? const WaterLoadingIndicator(
                          size: 24,
                          waveColor1: AppColors.white,
                        )
                      : Text(
                          AppLocalizations.of(context)!.continue_btn,
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
      ),
    );
  }
}
