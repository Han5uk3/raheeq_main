import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/formatters.dart';

/// The four fixed "Order Date" period options offered to the user.
enum OrderPeriod { thisMonth, lastMonth, last6Months, thisYear }

/// The selectable "Order Type" values, mirroring the `orderType` API enum.
enum OrderTypeFilter { general, gift, subscription }

extension OrderTypeFilterApiValue on OrderTypeFilter {
  String get apiValue {
    switch (this) {
      case OrderTypeFilter.general:
        return 'general';
      case OrderTypeFilter.gift:
        return 'gift';
      case OrderTypeFilter.subscription:
        return 'subscription';
    }
  }
}

/// The date range a given [OrderPeriod] resolves to for the API request.
class OrderPeriodParams {
  final String? preset;
  final String? startDate;
  final String? endDate;

  const OrderPeriodParams({this.preset, this.startDate, this.endDate});
}

/// The user's selection made inside the filter bottom sheet, returned once
/// the "Apply" button is pressed.
class OrdersFilterSelection {
  final OrderPeriod? period;
  final Set<OrderTypeFilter> orderTypes;

  const OrdersFilterSelection({this.period, this.orderTypes = const {}});

  bool get isEmpty => period == null && orderTypes.isEmpty;

  static const empty = OrdersFilterSelection();

  /// Resolves the selected [period] into the concrete query params expected
  /// by `GET /v1/orders` (`preset` or a `startDate`/`endDate` pair).
  OrderPeriodParams? resolvePeriodParams() {
    if (period == null) return null;
    final now = DateTime.now();
    // Pinned to en_US: these are query params, not display text, so they must
    // stay ASCII whatever locale intl is defaulting to. Left bare, the digits
    // follow Intl.getCurrentLocale() and an Arabic default would send
    // '٢٠٢٦-٠٦-٢٠' to GET /v1/orders.
    String fmt(DateTime d) =>
        DateFormat('yyyy-MM-dd', Formatters.englishLocale).format(d);

    switch (period!) {
      case OrderPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return OrderPeriodParams(startDate: fmt(start), endDate: fmt(end));
      case OrderPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return OrderPeriodParams(startDate: fmt(start), endDate: fmt(end));
      case OrderPeriod.last6Months:
        return const OrderPeriodParams(preset: 'last_6_months');
      case OrderPeriod.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return OrderPeriodParams(startDate: fmt(start), endDate: fmt(end));
    }
  }
}

/// Localized display label for a period option, e.g. "August 2026",
/// "July 2026", "Last 6 Months" or "This Year (2026)".
String orderPeriodLabel(BuildContext context, OrderPeriod period) {
  final now = DateTime.now();

  switch (period) {
    case OrderPeriod.thisMonth:
      return Formatters.formatMonthYear(context, now);
    case OrderPeriod.lastMonth:
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      return Formatters.formatMonthYear(context, lastMonth);
    case OrderPeriod.last6Months:
      return AppLocalizations.of(context)!.last_6_months;
    case OrderPeriod.thisYear:
      return '${AppLocalizations.of(context)!.this_year} (${now.year})';
  }
}

class OrdersFilterBottomSheet extends StatefulWidget {
  final OrdersFilterSelection initialSelection;

  const OrdersFilterBottomSheet({super.key, required this.initialSelection});

  /// Shows the filter bottom sheet and returns the applied selection, or
  /// `null` if the user dismissed the sheet without applying.
  static Future<OrdersFilterSelection?> show(
    BuildContext context, {
    required OrdersFilterSelection initialSelection,
  }) {
    return showModalBottomSheet<OrdersFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          OrdersFilterBottomSheet(initialSelection: initialSelection),
    );
  }

  @override
  State<OrdersFilterBottomSheet> createState() =>
      _OrdersFilterBottomSheetState();
}

class _OrdersFilterBottomSheetState extends State<OrdersFilterBottomSheet> {
  OrderPeriod? _period;
  late Set<OrderTypeFilter> _orderTypes;

  @override
  void initState() {
    super.initState();
    _period = widget.initialSelection.period;
    _orderTypes = {...widget.initialSelection.orderTypes};
  }

  Future<void> _openPeriodSelector() async {
    final selected = await showModalBottomSheet<OrderPeriod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PeriodSelectorSheet(selected: _period),
    );
    if (selected != null && mounted) {
      setState(() => _period = selected);
    }
  }

  void _toggleOrderType(OrderTypeFilter type) {
    setState(() {
      if (_orderTypes.contains(type)) {
        _orderTypes.remove(type);
      } else {
        _orderTypes.add(type);
      }
    });
  }

  void _clear() {
    setState(() {
      _period = null;
      _orderTypes = {};
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      OrdersFilterSelection(period: _period, orderTypes: _orderTypes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.filter_orders,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                loc.order_type,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OrderTypeChip(
                    label: loc.general_orders,
                    isSelected: _orderTypes.contains(OrderTypeFilter.general),
                    onTap: () => _toggleOrderType(OrderTypeFilter.general),
                  ),
                  _OrderTypeChip(
                    label: loc.gift_orders,
                    isSelected: _orderTypes.contains(OrderTypeFilter.gift),
                    onTap: () => _toggleOrderType(OrderTypeFilter.gift),
                  ),
                  _OrderTypeChip(
                    label: loc.subscription,
                    isSelected: _orderTypes.contains(
                      OrderTypeFilter.subscription,
                    ),
                    onTap: () => _toggleOrderType(OrderTypeFilter.subscription),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                loc.order_date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _openPeriodSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _period != null
                            ? AppColors.buttonBlueDark
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _period != null
                              ? orderPeriodLabel(context, _period!)
                              : loc.select_month,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _period != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _period != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          loc.clear_all,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          loc.apply,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.buttonBlueDark : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PeriodSelectorSheet extends StatelessWidget {
  final OrderPeriod? selected;

  const _PeriodSelectorSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.order_date,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...OrderPeriod.values.map((period) {
                final isSelected = selected == period;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.buttonBlueLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.buttonBlueDark
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              orderPeriodLabel(context, period),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.buttonBlueDark
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppColors.buttonBlueDark
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
