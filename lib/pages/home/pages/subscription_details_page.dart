import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/subscription_details_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raheeq_main/pages/home/pages/track_subscription_delivery_page.dart';
import 'package:raheeq_main/utils/formatters.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  final String subscriptionId;

  const SubscriptionDetailsPage({super.key, required this.subscriptionId});

  @override
  State<SubscriptionDetailsPage> createState() =>
      _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  SubscriptionDetailsModel? _details;

  /// The month the delivery calendar is showing. Set once the details arrive.
  DateTime? _calendarMonth;

  List<dynamic> get _allGiftCards {
    if (_details == null) return [];
    final list = <dynamic>[];
    if (_details!.giftCards.isNotEmpty) {
      list.addAll(_details!.giftCards);
    }
    for (var delivery in _details!.deliveries) {
      for (var sub in delivery.subOrders) {
        if (sub.giftCard != null) {
          list.add(sub.giftCard);
        }
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getSubscriptionDetails(
        widget.subscriptionId,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final details = SubscriptionDetailsModel.fromJson(data);
        setState(() {
          _details = details;
          _calendarMonth = _initialCalendarMonth(details);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = AppLocalizations.of(context)!.error;
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  String _formatPaymentMethod(BuildContext context, String method) {
    if (method.isEmpty) return '';
    final loc = AppLocalizations.of(context)!;
    switch (method.toUpperCase()) {
      case 'CREDIT_CARD':
      case 'MADA':
        return loc.credit_card_mada;
      case 'STC_PAY':
        return loc.stc_pay;
      case 'APPLE_PAY':
        return loc.apple_pay;
      case 'BANK_TRANSFER':
      case 'IBAN':
        return loc.iban_bank_transfer;
      default:
        final parts = method.split('_');
        return parts
            .map(
              (p) => p.isEmpty
                  ? ''
                  : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  /// Whole days from [from] to [to], ignoring the time of day.
  ///
  /// Both ends are normalised to UTC midnight so a daylight-saving shift in
  /// between cannot round the result off by a day.
  int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    return end.difference(start).inDays;
  }

  /// How much of the subscription is left, at month or day granularity.
  ///
  /// The countdown is measured from the start date, never from today, so a
  /// subscription that has not begun yet reads as its full length instead of
  /// counting the wait to get there.
  String _durationLeftLabel() {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final start = _details!.startDate.toLocal();
    final end = _details!.endDate.toLocal();

    final from = _daysBetween(now, start) > 0 ? start : now;
    final daysLeft = _daysBetween(from, end);

    if (daysLeft < 0) return loc.subscription_expired;
    // 30 days is a month here; the card only ever shows months or days.
    if (daysLeft >= 30) return loc.months_left(daysLeft ~/ 30);
    return loc.days_left(daysLeft);
  }

  /// Whether a delivery counts as done for the calendar's colouring.
  bool _isDelivered(String status) {
    final normalised = status.toUpperCase();
    return normalised == 'DELIVERED' || normalised == 'COMPLETED';
  }

  /// The subscription's delivery days, each flagged with whether every
  /// delivery falling on it has been completed.
  Map<DateTime, bool> _deliveryDays(SubscriptionDetailsModel details) {
    final days = <DateTime, bool>{};
    for (final delivery in details.deliveries) {
      final date = (delivery.scheduledDate ?? delivery.createdAt).toLocal();
      final day = DateTime(date.year, date.month, date.day);
      // Several deliveries can share a day; it only reads as done once all of
      // them are.
      days[day] = (days[day] ?? true) && _isDelivered(delivery.status);
    }
    return days;
  }

  /// Opens on the next delivery still to come, falling back to the last one,
  /// so the calendar never lands on a month with nothing in it.
  DateTime _initialCalendarMonth(SubscriptionDetailsModel details) {
    final now = DateTime.now();
    final days = _deliveryDays(details).keys.toList()..sort();
    if (days.isEmpty) return DateTime(now.year, now.month);

    final today = DateTime(now.year, now.month, now.day);
    final next = days.firstWhere(
      (day) => !day.isBefore(today),
      orElse: () => days.last,
    );
    return DateTime(next.year, next.month);
  }

  Widget _buildDeliveryCalendar(bool isAr) {
    final loc = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final deliveryDays = _deliveryDays(_details!);
    final month = _calendarMonth ?? _initialCalendarMonth(_details!);

    // Paging stays inside the months that actually hold deliveries.
    final sorted = deliveryDays.keys.toList()..sort();
    final firstMonth = DateTime(sorted.first.year, sorted.first.month);
    final lastMonth = DateTime(sorted.last.year, sorted.last.month);

    // The locale decides which weekday a week starts on, so the month's first
    // day is offset from that rather than from Sunday.
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final weekStart = material.firstDayOfWeekIndex;
    final leadingBlanks = (firstOfMonth.weekday % 7 - weekStart + 7) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.delivery_calendar,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.indicatorGrey.withAlpha(100)),
            Row(
              children: [
                // Leading in the reading direction, so it flips with the locale.
                _buildMonthArrow(
                  icon: Icons.chevron_left,
                  onPressed: month.isAfter(firstMonth)
                      ? () => setState(
                          () => _calendarMonth = DateTime(
                            month.year,
                            month.month - 1,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.center,
                    Formatters.formatMonthYear(context, month),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ),
                ),
                _buildMonthArrow(
                  icon: Icons.chevron_right,
                  onPressed: month.isBefore(lastMonth)
                      ? () => setState(
                          () => _calendarMonth = DateTime(
                            month.year,
                            month.month + 1,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Day numbers and weekday letters live in fixed-size cells, so cap
            // how far accessibility text scaling can push them.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Every column is an exact seventh of the card, so a weekday
                  // letter and the day numbers under it can never drift apart.
                  // The squircle keeps its design size wherever it fits and
                  // only shrinks on a display too narrow for it, rather than
                  // overflowing its column.
                  final columnWidth = constraints.maxWidth / 7;
                  final cellSize = (columnWidth - 4).clamp(24.0, 40.0);
                  final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

                  return Column(
                    children: [
                      Row(
                        children: List.generate(7, (index) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                material.narrowWeekdays[(weekStart + index) %
                                    7],
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      ...List.generate(rowCount, (row) {
                        return SizedBox(
                          height: cellSize + 4,
                          child: Row(
                            children: List.generate(7, (column) {
                              final day = row * 7 + column - leadingBlanks + 1;
                              return Expanded(
                                child: day < 1 || day > daysInMonth
                                    ? const SizedBox.shrink()
                                    : _buildCalendarDay(
                                        month,
                                        day,
                                        deliveryDays,
                                        cellSize,
                                      ),
                              );
                            }),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            Divider(height: 16, color: AppColors.indicatorGrey.withAlpha(100)),

            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildCalendarLegend(Colors.green, loc.delivered),
                _buildCalendarLegend(
                  AppColors.buttonBlueDark.withValues(alpha: 50),
                  loc.upcoming,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthArrow({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: AppColors.buttonBlueDark,
      disabledColor: AppColors.indicatorGrey,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildCalendarDay(
    DateTime month,
    int day,
    Map<DateTime, bool> deliveryDays,
    double size,
  ) {
    final date = DateTime(month.year, month.month, day);
    final isDelivery = deliveryDays.containsKey(date);
    final fill = isDelivery
        ? (deliveryDays[date]! ? Colors.green : AppColors.buttonBlueDark)
        : null;

    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill?.withAlpha(40),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDelivery
                      ? FontWeight.bold
                      : FontWeight.normal,
                  // The tint carries the status, so the numeral stays high contrast.
                  color: AppColors.black,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Same tint as a day cell, outlined so it still reads at this size.
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.subscription_details;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        color: AppColors.buttonBlueDark,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: title,
                subtitle: _details?.subscriptionNumber ?? '',
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
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
                        children: <Widget>[...previousChildren, ?currentChild],
                      );
                    },
                    child: _buildContent(isAr),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _fetchDetails,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (_details == null) {
      return Center(
        key: const ValueKey('empty'),
        child: Text(AppLocalizations.of(context)!.no_details_found),
      );
    }
    bool shouldShowDeliveries = false;
    bool hasGiftCardOrInvoice =
        _details!.giftCards.isNotEmpty ||
        (_details!.invoiceUrl != null && _details!.invoiceUrl!.isNotEmpty);
    return Padding(
      key: const ValueKey('content'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(isAr),
          if (hasGiftCardOrInvoice) ...[
            const SizedBox(height: 24),
            _buildGiftInvoiceButtonRow(),
          ],
          _buildDurationInfoCard(isAr),
          if (_details!.targets.isNotEmpty) ...[
            const SizedBox(height: 24),

            _buildTargetsCard(isAr),
          ],
          if (_details!.products.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildProductsCard(isAr),
          ],
          if (_details!.deliveries.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDeliveryCalendar(isAr),
          ],
         

          if (shouldShowDeliveries) ...[
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.deliveries,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.buttonBlueDark,
              ),
            ),
            const SizedBox(height: 12),
            if (_details!.deliveries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.no_deliveries_found,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._details!.deliveries.map(
                (delivery) => _buildDeliveryCard(delivery, isAr),
              ),
          ],
        ],
      ),
    );
  }

Widget _buildProductsCard(bool isAr) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.products,
                style: TextStyle(fontSize: 14, color: AppColors.black),
              ),
              Divider(height: 24),
              ..._details!.products.map((product) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.buttonBlueDark),
                    ),
                    child: Row(
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? product.nameAr : product.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTargetsCard(bool isAr) {
    final targets = _details!.targets;

    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.delivery_locations,
                style: TextStyle(fontSize: 14, color: AppColors.black),
              ),
              Divider(height: 24),
              ...targets.map((target) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.buttonBlueDark),
                    ),
                    child: Row(
                      children: [
                        if (target.image.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: target.image,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 32,
                                height: 32,
                                color: Colors.grey[300],
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.buttonBlueDark,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.buttonBlueDark,
                          ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAr ? target.nameAr : target.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.black,
                                ),
                              ),
                              if (target.address.isNotEmpty) ...[
                                SizedBox(height: 2),
                                Text(
                                  target.address,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildDurationInfoCard(bool isAr) {
    return Material(
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
            // Card Body
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.subscription_duration,
                        style: TextStyle(fontSize: 12, color: AppColors.black),
                      ),
                      Text(
                        _durationLeftLabel(),
                        style: TextStyle(fontSize: 12, color: AppColors.black),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.start_date,
                        style: TextStyle(fontSize: 12, color: AppColors.black),
                      ),
                      Text(
                        AppLocalizations.of(context)!.expires_on,
                        style: TextStyle(fontSize: 12, color: AppColors.black),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Deliveries completed out of the total for the plan.
                  _buildProgressBar(_details!, isAr),
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
                          Formatters.formatDate(context, _details!.startDate),
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
                          Formatters.formatDate(context, _details!.endDate),
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
    );
  }

  Widget _buildGiftInvoiceButtonRow() {
    return Row(
      spacing: 16,
      children: [
        if (_details!.invoiceUrl != null &&
            _details!.invoiceUrl!.isNotEmpty) ...[
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final url = Uri.parse(_details!.invoiceUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  if (mounted) {
                    CustomSnackbar.show(
                      context: context,
                      message: AppLocalizations.of(
                        context,
                      )!.could_not_open_invoice,
                    );
                  }
                }
              },
              icon: const Icon(Icons.receipt, color: Colors.white, size: 18),
              label: Text(
                AppLocalizations.of(context)!.view_invoice,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
        if (_allGiftCards.isNotEmpty) ...[
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () =>
                  _showGiftCardsBottomSheet(context, _allGiftCards),
              icon: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                AppLocalizations.of(context)!.show_gift_cards,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Height of one line of text at [fontSize], measured with the font, locale
  /// and text scale the loaded card will use.
  ///
  /// Arabic resolves to a taller fallback face than the Latin one — 19px to 17
  /// at a font size of 12 — so a bar with a hardcoded height leaves the
  /// skeleton and the loaded card at different heights in one locale or the
  /// other, and the page shifts as it loads.
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

  /// The same card chrome the loaded sections use, wrapped around a skeleton.
  Widget _skeletonCard({required Widget child}) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );
  }

  /// Mirrors [_buildInfoCard]: plan image, name over frequency, status pill,
  /// then the delivered-count banner.
  Widget _skeletonInfoCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: 60, height: 60, radius: 8),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonTextBar(width: 150, fontSize: 18),
                        const SizedBox(height: 4),
                        _skeletonTextBar(width: 90, fontSize: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // The pill wraps its label in 6px of vertical padding.
                  _skeletonBox(
                    width: 84,
                    height: _lineHeight(12) + 12,
                    radius: 10,
                  ),
                ],
              ),
              const Divider(height: 32),
              // The banner pads its label by 8px top and bottom.
              _skeletonBox(
                width: double.infinity,
                height: _lineHeight(12) + 16,
                radius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors [_buildDurationInfoCard]: two label rows around the progress bar,
  /// with the start and end date chips beneath it.
  Widget _skeletonDurationCard() {
    return _skeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _skeletonTextBar(width: 120, fontSize: 12),
              _skeletonTextBar(width: 70, fontSize: 12),
            ],
          ),
          const Divider(height: 24),
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
              _skeletonBox(width: 76, height: _lineHeight(10) + 8, radius: 8),
              _skeletonBox(width: 76, height: _lineHeight(10) + 8, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  /// Mirrors [_buildTargetsCard] and [_buildProductsCard], which share a
  /// layout and differ only in thumbnail size.
  Widget _skeletonListCard({required double thumbSize, int rows = 2}) {
    return _skeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _skeletonTextBar(width: 110, fontSize: 14),
          ),
          const Divider(height: 24),
          ...List.generate(
            rows,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white),
                ),
                child: Row(
                  children: [
                    _skeletonBox(
                      width: thumbSize,
                      height: thumbSize,
                      radius: 4,
                    ),
                    const SizedBox(width: 8),
                    _skeletonTextBar(width: 130, fontSize: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mirrors [_buildDeliveryCalendar]: month pager, weekday letters, a grid of
  /// day cells, then the legend.
  Widget _skeletonCalendarCard() {
    return _skeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _skeletonTextBar(width: 130, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // The month arrows are IconButtons with a 32px minimum.
          SizedBox(
            height: 32,
            child: Row(
              children: [
                _skeletonBox(width: 20, height: 20, radius: 4),
                Expanded(
                  child: Center(
                    child: _skeletonTextBar(width: 90, fontSize: 12),
                  ),
                ),
                _skeletonBox(width: 20, height: 20, radius: 4),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // The same column maths the real calendar uses, so the skeleton
              // cells sit where the day cells will.
              final cellSize = (constraints.maxWidth / 7 - 4).clamp(24.0, 40.0);

              return Column(
                children: [
                  Row(
                    children: List.generate(
                      7,
                      (index) => Expanded(
                        child: Center(
                          child: _skeletonTextBar(width: 10, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    5,
                    (row) => SizedBox(
                      height: cellSize + 4,
                      child: Row(
                        children: List.generate(
                          7,
                          (column) => Expanded(
                            child: Center(
                              child: _skeletonBox(
                                width: cellSize,
                                height: cellSize,
                                radius: 6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 16),
          Row(
            children: [
              _skeletonBox(width: 12, height: 12, radius: 4),
              const SizedBox(width: 6),
              _skeletonTextBar(width: 60, fontSize: 11),
              const SizedBox(width: 20),
              _skeletonBox(width: 12, height: 12, radius: 4),
              const SizedBox(width: 6),
              _skeletonTextBar(width: 60, fontSize: 11),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      key: const ValueKey('loader'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonInfoCard(),
          _skeletonDurationCard(),
          const SizedBox(height: 24),
          // Targets and products are both optional, but standing in for them
          // keeps the calendar from jumping up the page once it loads.
          _skeletonListCard(thumbSize: 32),
          const SizedBox(height: 24),
          _skeletonListCard(thumbSize: 40, rows: 1),
          const SizedBox(height: 24),
          _skeletonCalendarCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isAr) {
    final Color statusColor = _details!.status.toLowerCase() == 'active'
        ? Colors.green
        : Colors.red;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_details!.planImage.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _details!.planImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? _details!.planNameAr : _details!.planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.buttonBlueDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _localizeFrequency(_details!.frequency),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
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
                        _localizeStatus(_details!.status, context),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.delivered_x_of_y_orders(
                    _details?.completeCount ?? 0,
                    _details?.ordersCount ?? 0,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 

  Widget _buildDeliveryCard(SubscriptionDeliveryModel delivery, bool isAr) {
    String dateFormat(DateTime date) => Formatters.formatDate(context, date);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackSubscriptionDeliveryPage(
              orderId: delivery.orderId,
              subOrderId: delivery.subOrders.isNotEmpty
                  ? delivery.subOrders.first.id
                  : "",
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${delivery.orderNumber}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: AppColors.buttonBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              delivery.scheduledDate != null
                                  ? dateFormat(delivery.scheduledDate!)
                                  : dateFormat(delivery.createdAt),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
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

  Widget _buildSubOrder(
    SubscriptionSubOrderModel subOrder,
    bool isAr,
    String orderId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (subOrder.product != null &&
              subOrder.product!.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                subOrder.product!.image,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subOrder.product != null)
                  Text(
                    '${subOrder.product!.quantity}x ${isAr ? subOrder.product!.nameAr : subOrder.product!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.buttonBlueDark,
                    ),
                  ),
                if (subOrder.target != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isAr
                              ? subOrder.target!.labelAr
                              : subOrder.target!.label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(subOrder.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _localizeStatus(subOrder.status, context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(subOrder.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PROCESSING':
        return Colors.orange;
      case 'DISPATCHED':
      case 'OUT_FOR_DELIVERY':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _localizeFrequency(String frequency) {
    final freq = frequency.toLowerCase().trim();
    if (freq == 'everyday') {
      return AppLocalizations.of(context)!.everyday;
    } else if (freq == 'once_a_week') {
      return AppLocalizations.of(context)!.once_a_week;
    } else if (freq == 'once_a_month') {
      return AppLocalizations.of(context)!.once_a_month;
    } else if (freq == 'twice_a_week') {
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

    return status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1).toLowerCase()
        : '';
  }

  void _showGiftCardsBottomSheet(
    BuildContext context,
    List<dynamic> giftCards,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.added_gift_cards,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonBlueDark,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: giftCards.length == 1 ? 300 : 250,
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: giftCards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final giftCard = giftCards[index];
                    final String? imageUrl = giftCard is Map
                        ? giftCard['generatedImage']
                        : null;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: giftCards.length == 1
                            ? MediaQuery.of(context).size.width - 48
                            : 200,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(SubscriptionDetailsModel subscription, bool isAr) {
    // A missing `totalCount` means the API has not been updated yet; the two
    // counts arrive together, so fall back to the pair rather than to a
    // separate default per field, which would report 1 completed delivery on a
    // subscription the API says has none.
    final bool hasCounts = subscription.ordersCount > 0;
    final int total = hasCounts ? subscription.ordersCount : 10;
    final int completed = hasCounts
        ? subscription.completeCount.clamp(0, total)
        : 1;

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
}
