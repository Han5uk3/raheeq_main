import 'package:flutter/material.dart';
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkTokeniseType.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'dart:developer';

import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:dio/dio.dart';
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';

class ContributionDetailsPage extends StatefulWidget {
  final List<OrderCategoryState> orderStates;
  final String donationType;
  final Checkout checkoutData;

  const ContributionDetailsPage({
    super.key,
    required this.orderStates,
    required this.donationType,
    required this.checkoutData,
  });

  @override
  State<ContributionDetailsPage> createState() =>
      _ContributionDetailsPageState();
}

class _ContributionDetailsPageState extends State<ContributionDetailsPage> {
  late Checkout _checkoutData;
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  bool _isTogglingWallet = false;

  @override
  void initState() {
    super.initState();
    _checkoutData = widget.checkoutData;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(bool isAr) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.applyCoupon(code);
      log('Apply coupon response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _checkoutData = Checkout.fromJson(response.data['data']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'تم تطبيق الكوبون بنجاح' : 'Coupon applied successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to apply coupon');
      }
    } catch (e) {
      log('Error applying coupon: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'كوبون غير صالح' : 'Invalid coupon code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCoupon = false;
        });
      }
    }
  }

  void _removeCoupon(bool isAr) async {
    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.removeCoupon();
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _checkoutData = Checkout.fromJson(response.data['data']);
          _couponController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr ? 'تم إزالة الكوبون بنجاح' : 'Coupon removed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to remove coupon');
      }
    } catch (e) {
      log('Error removing coupon: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'حدث خطأ أثناء إزالة الكوبون' : 'Failed to remove coupon',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingCoupon = false;
        });
      }
    }
  }

  void _toggleWallet(bool useWallet, bool isAr) async {
    setState(() {
      _isTogglingWallet = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.toggleWallet(useWallet);
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _checkoutData = Checkout.fromJson(response.data['data']);
        });
      } else {
        throw Exception('Failed to toggle wallet');
      }
    } on DioException catch (e) {
      log('Error toggling wallet: $e', error: e);
      if (mounted) {
        String errorMessage = isAr
            ? 'حدث خطأ أثناء تطبيق المحفظة'
            : 'Failed to apply wallet';

        if (e.response?.statusCode == 400 &&
            e.response?.data is Map &&
            (e.response?.data['message']?.toString().toLowerCase().contains(
                      'invalid wallet usage',
                    ) ==
                    true ||
                e.response?.data['message']?.toString().toLowerCase().contains(
                      'insufficient balance',
                    ) ==
                    true)) {
          errorMessage = isAr
              ? 'رصيد غير كافٍ لتطبيق المحفظة'
              : 'Insufficient balance to apply wallet';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      log('Error toggling wallet: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'حدث خطأ أثناء تطبيق المحفظة' : 'Failed to apply wallet',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingWallet = false;
        });
      }
    }
  }

  void _confirmAndPay(BuildContext context, bool isAr) {
    // Basic Paytabs integration setup
    final billingDetails = BillingDetails(
      "John Smith",
      "email@domain.com",
      "+97311111111",
      "st. 12",
      "ae",
      "dubai",
      "dubai",
      "12345",
    );

    final shippingDetails = ShippingDetails(
      "John Smith",
      "email@domain.com",
      "+97311111111",
      "st. 12",
      "ae",
      "dubai",
      "dubai",
      "12345",
    );

    final amount = _checkoutData.finalTotal.toDouble();

    final configuration = PaymentSdkConfigurationDetails(
      profileId: "*profile id*",
      serverKey: "*server key*",
      clientKey: "*client key*",
      cartId: _checkoutData.id,
      cartDescription: "Donation Order",
      merchantName: "Raheeq",
      screentTitle: isAr ? "الدفع" : "Pay with Card",
      amount: amount > 0 ? amount : 1.0, // Amount should be > 0
      showBillingInfo: true,
      forceShippingInfo: false,
      currencyCode: "SAR",
      merchantCountryCode: "SA",
      billingDetails: billingDetails,
      shippingDetails: shippingDetails,
      alternativePaymentMethods: [],
      linkBillingNameWithCardHolderName: true,
    );

    final theme = IOSThemeConfigurations();
    theme.logoImage = "assets/logo.png";
    configuration.iOSThemeConfigurations = theme;
    configuration.tokeniseType = PaymentSdkTokeniseType.NONE;

    FlutterPaytabsBridge.startCardPayment(configuration, (event) {
      setState(() {
        if (event["status"] == "success") {
          var transactionDetails = event["data"];
          
          if (transactionDetails["isSuccess"]) {
            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: Text(isAr ? 'نجاح' : 'Success'),
                  content: Text(
                    isAr
                        ? 'تم الدفع بنجاح!'
                        : 'Payment completed successfully!',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: Text(isAr ? 'حسناً' : 'OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isAr ? 'فشلت عملية الدفع' : 'Payment failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (event["status"] == "error") {
          // Handle error here.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${event["message"]}"),
              backgroundColor: Colors.red,
            ),
          );
        } else if (event["status"] == "event") {
          // Handle events here.
        }
      });
    });
  }

  Widget _buildSubscriptionDetails(bool isAr) {
    if (_checkoutData.subscription == null) return const SizedBox.shrink();

    final sub = _checkoutData.subscription;
    if (sub is! Map) return const SizedBox.shrink();

    final startDate = sub['startDate'] != null
        ? DateTime.tryParse(sub['startDate'].toString())
        : null;
    final endDate = sub['endDate'] != null
        ? DateTime.tryParse(sub['endDate'].toString())
        : null;
    final months = sub['months'] as int?;
    final daysOfWeek = (sub['daysOfWeek'] as List<dynamic>?)?.cast<int>();

    // Infer type or get from plan if available
    String type = '';
    final plan = sub['plan'];
    if (plan != null && plan is Map && plan['type'] != null) {
      type = plan['type'].toString().toUpperCase();
    } else {
      if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
        type = 'WEEKLY';
      } else if (endDate != null) {
        type = 'EVERYDAY';
      } else {
        type = 'MONTHLY';
      }
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    List<Widget> rows = [];

    if (type == 'EVERYDAY' || type == 'EVERY_DAY' || type == 'DAILY') {
      if (startDate != null && endDate != null) {
        final days =
            endDate.difference(startDate).inDays + 1; // Assuming inclusive
        rows.add(
          _buildSubscriptionRow(isAr ? 'عدد الأيام' : 'Total Days', '$days'),
        );
        rows.add(
          _buildSubscriptionRow(
            isAr ? 'تاريخ البدء' : 'Start Date',
            dateFormat.format(startDate),
          ),
        );
        rows.add(
          _buildSubscriptionRow(
            isAr ? 'تاريخ الانتهاء' : 'End Date',
            dateFormat.format(endDate),
          ),
        );
      }
    } else if (type == 'MONTHLY' || type == 'ONCE_A_MONTH') {
      if (months != null) {
        rows.add(
          _buildSubscriptionRow(isAr ? 'عدد الأشهر' : 'Months', '$months'),
        );
      }
      if (startDate != null) {
        rows.add(
          _buildSubscriptionRow(
            isAr ? 'تاريخ البدء' : 'Start Date',
            dateFormat.format(startDate),
          ),
        );
      }
    } else if (type == 'WEEKLY' ||
        type == 'ONCE_A_WEEK' ||
        type == 'TWICE_A_WEEK') {
      if (months != null) {
        rows.add(
          _buildSubscriptionRow(isAr ? 'عدد الأشهر' : 'Months', '$months'),
        );
      }
      if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
        final daysMapAr = {
          1: 'الاثنين',
          2: 'الثلاثاء',
          3: 'الأربعاء',
          4: 'الخميس',
          5: 'الجمعة',
          6: 'السبت',
          7: 'الأحد',
        };
        final daysMapEn = {
          1: 'Mon',
          2: 'Tue',
          3: 'Wed',
          4: 'Thu',
          5: 'Fri',
          6: 'Sat',
          7: 'Sun',
        };
        final selectedDays = daysOfWeek
            .map((d) => isAr ? daysMapAr[d] : daysMapEn[d])
            .join(', ');
        rows.add(
          _buildSubscriptionRow(
            isAr ? 'أيام التوصيل' : 'Delivery Days',
            selectedDays,
          ),
        );
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تفاصيل الاشتراك' : 'Subscription Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonBlueDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.buttonBlue.withValues(alpha: 0.1),
              ),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.buttonBlueDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? 'الدفع' : 'Payment';
    final subtitle = isAr ? 'مراجعة نهائية ودفع' : 'Final review and payment';

    final Map<String, SelectedProduct> aggregatedProducts = {};
    if (widget.orderStates.isNotEmpty) {
      for (final state in widget.orderStates) {
        for (final sp in state.selectedProducts) {
          final key = sp.product.id;
          if (aggregatedProducts.containsKey(key)) {
            aggregatedProducts[key]!.quantity += sp.quantity;
          } else {
            aggregatedProducts[key] = SelectedProduct(
              product: sp.product,
              quantity: sp.quantity,
            );
          }
        }
      }
    } else {
      for (final item in _checkoutData.items) {
        if (item.product != null) {
          final key = item.product!.id;
          if (aggregatedProducts.containsKey(key)) {
            aggregatedProducts[key]!.quantity += item.quantity;
          } else {
            aggregatedProducts[key] = SelectedProduct(
              product: item.product!,
              quantity: item.quantity,
            );
          }
        }
      }
    }

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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0x4D91E3FE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      widget.donationType.contains('Monthly') ||
                                              widget.donationType.contains(
                                                'شهري',
                                              )
                                          ? Icons.autorenew
                                          : Icons.favorite,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAr ? 'نوع التبرع' : 'Donation Type',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.donationType,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.buttonBlueDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                //todo gift card workflow
                              },
                              child: Card(
                                color: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.buttonBlueDark,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Image.asset(
                                          "assets/giftcard.png",
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              size: 24,
                                              Icons.card_giftcard_outlined,
                                              color: AppColors.buttonBlueDark,
                                            ),
                                            Text(
                                              isAr
                                                  ? 'هل ترغب في إهداء شخص قريب منك؟'
                                                  : 'Do you want to give a gift to someone close to you?',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: AlignmentDirectional
                                                  .centerEnd,
                                              child: Container(
                                                height: 28,
                                                width: 28,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  size: 12,
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'كود الخصم' : 'Coupon Code',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_checkoutData.couponCode != null &&
                                        _checkoutData.couponCode!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _checkoutData.couponCode!,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: _isApplyingCoupon
                                                  ? null
                                                  : () => _removeCoupon(isAr),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: _isApplyingCoupon
                                                  ? const WaterLoadingIndicator(
                                                      size: 16,
                                                      waveColor1: Colors.white,
                                                      waveColor2: Colors.white,
                                                    )
                                                  : Text(
                                                      isAr ? 'إزالة' : 'Remove',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: TextField(
                                                cursorColor: Colors.grey,
                                                controller: _couponController,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  hintText: isAr
                                                      ? 'أدخل كود الخصم'
                                                      : 'Enter coupon code',
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed: _isApplyingCoupon
                                                ? null
                                                : () => _applyCoupon(isAr),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.buttonBlueDark,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _isApplyingCoupon
                                                ? const WaterLoadingIndicator(
                                                    size: 16,
                                                    waveColor1: Colors.white,
                                                    waveColor2: Colors.white,
                                                  )
                                                : Text(
                                                    isAr ? 'تطبيق' : 'Apply',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_checkoutData.walletBalance > 0) ...[
                              Card(
                                color: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              color: AppColors.buttonBlueDark,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isAr
                                                        ? 'استخدام المحفظة'
                                                        : 'Use Wallet Balance',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    isAr
                                                        ? 'الرصيد المتاح: ${_checkoutData.walletBalance.toStringAsFixed(2)} ر.س'
                                                        : 'Available: ${_checkoutData.walletBalance.toStringAsFixed(2)} SAR',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: _isTogglingWallet
                                            ? null
                                            : () => _toggleWallet(
                                                !_checkoutData.useWallet,
                                                isAr,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _checkoutData.useWallet
                                              ? Colors.red
                                              : AppColors.buttonBlueDark,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isTogglingWallet
                                            ? const WaterLoadingIndicator(
                                                size: 16,
                                                waveColor1: Colors.white,
                                                waveColor2: Colors.white,
                                              )
                                            : Text(
                                                _checkoutData.useWallet
                                                    ? (isAr
                                                          ? 'إزالة'
                                                          : 'Remove')
                                                    : (isAr
                                                          ? 'تطبيق'
                                                          : 'Apply'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Card(
                              color: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr
                                          ? 'تفاصيل المساهمة'
                                          : 'Contribution Details',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ...aggregatedProducts.values.map((sp) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${sp.quantity} ${sp.product.localizedName(isAr)}",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              isAr
                                                  ? "${(sp.product.price * sp.quantity).toStringAsFixed(2)} ر.س"
                                                  : "${(sp.product.price * sp.quantity).toStringAsFixed(2)} SAR",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    _buildSubscriptionDetails(isAr),
                                    const Divider(height: 16),
                                    _buildPriceRow(
                                      isAr ? 'المجموع الفرعي' : 'Subtotal',
                                      _checkoutData.subTotal,
                                      isAr,
                                    ),
                                    if ((_checkoutData.totalDeliveryFee > 0
                                            ? _checkoutData.totalDeliveryFee
                                            : widget
                                                  .checkoutData
                                                  .totalDeliveryFee) >
                                        0)
                                      _buildPriceRow(
                                        isAr ? 'رسوم التوصيل' : 'Delivery Fee',
                                        _checkoutData.totalDeliveryFee > 0
                                            ? _checkoutData.totalDeliveryFee
                                            : widget
                                                  .checkoutData
                                                  .totalDeliveryFee,
                                        isAr,
                                        isFree: _checkoutData.isFreeDelivery,
                                      ),
                                    if (_checkoutData.vatAmount > 0)
                                      _buildPriceRow(
                                        isAr ? 'ضريبة القيمة المضافة' : 'VAT',
                                        _checkoutData.vatAmount,
                                        isAr,
                                      ),
                                    if (_checkoutData.discountAmount > 0)
                                      _buildPriceRow(
                                        isAr ? 'الخصم' : 'Discount',
                                        -_checkoutData.discountAmount,
                                        isAr,
                                      ),
                                    if (_checkoutData.walletAmountUsed > 0)
                                      _buildPriceRow(
                                        isAr
                                            ? 'رصيد المحفظة المستخدم'
                                            : 'Wallet Applied',
                                        -_checkoutData.walletAmountUsed,
                                        isAr,
                                      ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isAr
                                              ? 'إجمالي المبلغ'
                                              : 'Total Amount',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isAr
                                              ? '${_checkoutData.finalTotal.toStringAsFixed(2)} ر.س'
                                              : 'SAR ${_checkoutData.finalTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.buttonBlueDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: BottomActionPill(
                        subtitleWidget: Text(
                          isAr ? 'المجموع النهائي' : 'Total Amount',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        titleWidget: Text(
                          isAr
                              ? '${_checkoutData.finalTotal.toStringAsFixed(2)} ر.س'
                              : 'SAR ${_checkoutData.finalTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        buttonText: isAr ? 'تأكيد ودفع' : 'Confirm & Pay',
                        onButtonTap: () => _confirmAndPay(context, isAr),
                      ),
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

  Widget _buildPriceRow(
    String title,
    dynamic amount,
    bool isAr, {
    bool isFree = false,
  }) {
    if (amount == null) return const SizedBox.shrink();
    final double value = (amount is int) ? amount.toDouble() : amount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Row(
            children: [
              Text(
                isAr
                    ? '${value.toStringAsFixed(2)} ر.س'
                    : '${value.toStringAsFixed(2)} SAR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isFree ? FontWeight.normal : FontWeight.w600,
                  decoration: isFree ? TextDecoration.lineThrough : null,
                  color: isFree ? Colors.grey : null,
                ),
              ),
              if (isFree) ...[
                const SizedBox(width: 8),
                Text(
                  isAr ? 'مجانًا' : 'Free',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
