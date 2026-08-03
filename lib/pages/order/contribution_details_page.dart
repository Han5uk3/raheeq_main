import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:raheeq_main/pages/order/payment_success.dart';
import 'package:raheeq_main/services/network_monitor.dart';
import 'package:raheeq_main/services/snackbar_insets_services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkTokeniseType.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkLocale.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
import 'package:raheeq_main/pages/order/payment_status_page.dart';
import 'package:raheeq_main/pages/order/choose_iban_account_bottom_sheet.dart';
import 'package:raheeq_main/models/order_item.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/common_widgets/bottom_action_pill.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/gift_card_bottom_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart';
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';

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
  bool _isProcessingPayment = false;
  String _selectedPaymentMethod = Platform.isIOS ? 'APPLE_PAY' : 'STC_PAY';

  @override
  void initState() {
    super.initState();
    SnackbarInsets.setBottomInset(kBottomNavigationBarHeight);
    _checkoutData = widget.checkoutData;
    _couponController.addListener(_onCouponChanged);
  }

  void _onCouponChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    SnackbarInsets.clear();
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(bool isAr) async {
    if (NetworkMonitor.instance.status == NetworkStatus.offline) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.internet_error,
        isError: true,
      );
      return;
    }
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
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.coupon_applied_successfully,
          );
        }
      } else {
        throw Exception('Failed to apply coupon');
      }
    } catch (e) {
      log('Error applying coupon: $e', error: e);
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)!.invalid_coupon_code;
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
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
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.coupon_removed_successfully,
          );
        }
      } else {
        throw Exception('Failed to remove coupon');
      }
    } catch (e) {
      log('Error removing coupon: $e', error: e);
      if (mounted) {
        String errorMessage = AppLocalizations.of(
          context,
        )!.failed_to_remove_coupon;
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
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
      if (NetworkMonitor.instance.status == NetworkStatus.offline) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.internet_error,
          isError: true,
        );
        return;
      }

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
        String errorMessage = AppLocalizations.of(
          context,
        )!.failed_to_apply_wallet;

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
          errorMessage = AppLocalizations.of(
            context,
          )!.insufficient_balance_to_apply_wallet;
        } else if (e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }

        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      log('Error toggling wallet: $e', error: e);
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.failed_to_apply_wallet,
          isError: true,
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
    if (NetworkMonitor.instance.status == NetworkStatus.offline) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.internet_error,
        isError: true,
      );
      return;
    }
    log(
      'Payment Flow Started: Confirm & Pay clicked. Total Amount: ${_checkoutData.finalTotal}',
      name: 'CheckoutFlow',
    );
    if (_checkoutData.finalTotal == 0) {
      log(
        'Payment Flow: Order total is 0. Bypassing SDK.',
        name: 'CheckoutFlow',
      );
      _processPayment(
        context,
        isAr,
        'CREDIT_CARD',
      ); // Method doesn't matter for 0 total
      return;
    }

    if (_selectedPaymentMethod == 'IBAN') {
      log('Payment Flow: Selected IBAN', name: 'CheckoutFlow');
      ChooseIbanAccountBottomSheet.showAsBottomSheet(
        context,
        isAr: isAr,
        checkoutData: _checkoutData,
      );
    } else {
      log(
        'Payment Flow: Selected $_selectedPaymentMethod',
        name: 'CheckoutFlow',
      );
      _processPayment(context, isAr, _selectedPaymentMethod);
    }
  }

  Widget _buildPaymentMethods(bool isAr) {
    final methods = [
      if (Platform.isIOS)
        {
          'id': 'APPLE_PAY',
          'hasTwoIcons': false,
          'icon': "assets/payment_method_icons/apple_pay.png",
        },
      {
        'id': 'STC_PAY',
        'hasTwoIcons': false,
        'icon': "assets/payment_method_icons/stc_pay.png",
      },
      {
        'id': 'CREDIT_CARD',
        'hasTwoIcons': true,
        'icon': "assets/payment_method_icons/visa.png",
        'icon2': "assets/payment_method_icons/mada.png",
      },
      if (_checkoutData.subscription == null)
        {
          'id': 'IBAN',
          'hasTwoIcons': false,
          'icon': "assets/payment_method_icons/iban.png",
        },
    ];

    return Card(
      margin: EdgeInsets.all(0),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.payment_method,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...methods.expand((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: RadioListTile<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        width: isSelected ? 2 : 1,
                        color: isSelected
                            ? AppColors.buttonBlueDark
                            : AppColors.grey,
                      ),
                    ),
                    contentPadding: EdgeInsetsDirectional.only(start: 8),
                    value: method['id'] as String,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },

                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          method['icon'] as String,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                        if (method['hasTwoIcons'] == true) ...{
                          const SizedBox(width: 8),
                          Image.asset(
                            method['icon2'] as String,
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                        },
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    fillColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.buttonBlueDark;
                      }
                      return AppColors.grey;
                    }),
                  ),
                ),
                if (method['id'] != methods.last['id'])
                  const SizedBox(height: 12),
              ];
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    bool isAr,
    String paymentMethod,
  ) async {
    if (NetworkMonitor.instance.status == NetworkStatus.offline) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.internet_error,
        isError: true,
      );
      return;
    }
    log(
      'Payment Flow: Starting _processPayment with method: $paymentMethod',
      name: 'CheckoutFlow',
    );

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final apiService = ApiService();
      log('Payment Flow: Calling createOrder API...', name: 'CheckoutFlow');
      final response = await apiService.createOrder(
        paymentMethod: paymentMethod,
      );

      final data = response.data['data'];
      final paymentStatus = data['paymentStatus'];
      final orderId = data['orderId'] ?? data['id'];
      final orderNumber = data['orderNumber'];
      final paymentId = data['paymentId'];
      final paymentConfig = data['paymentConfig'];
      log(
        'Payment Flow: createOrder Response -> paymentStatus: $paymentStatus, orderId: $orderId, paymentId: $paymentId',
        name: 'CheckoutFlow',
      );

      if (paymentStatus == 'PAID' || _checkoutData.finalTotal == 0) {
        log(
          'Payment Flow: Status is PAID or Total is 0. Bypassing SDK.',
          name: 'CheckoutFlow',
        );
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              status: PaymentStatus.success,
              isAr: isAr,
              orderId: orderNumber?.toString() ?? orderId?.toString(),
            ),
          ),
        );
      } else if (paymentStatus == 'PENDING' && paymentConfig != null) {
        log(
          'Payment Flow: Status is PENDING. Preparing SDK configuration.',
          name: 'CheckoutFlow',
        );
        final amount = (paymentConfig['amount'] ?? _checkoutData.finalTotal)
            .toDouble();

        final user = AuthStorage.user;
        String userEmail = user?.email ?? '';
        if (userEmail.isEmpty) {
          final rawUsername =
              (user != null &&
                  (user.firstName.isNotEmpty || user.lastName.isNotEmpty))
              ? '${user.firstName}${user.lastName}'
              : 'customer';
          final sanitizedUsername = rawUsername.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          userEmail =
              '${sanitizedUsername.isNotEmpty ? sanitizedUsername : "customer"}@rahiq.app';
        }
        final userName = AuthStorage.user?.fullName ?? "Customer";
        final userPhone = (AuthStorage.user?.phoneNumber.isNotEmpty ?? false)
            ? AuthStorage.user!.phoneNumber
            : "+966500000000";

        final billingDetails = BillingDetails(
          AuthStorage.user?.fullName ?? "Customer",
          userEmail,
          userPhone,
          "st. 12",
          "sa",
          "Riyadh",
          "Riyadh",
          "12345",
        );

        final shippingDetails = ShippingDetails(
          userName,
          userEmail,
          userPhone,
          "st. 12",
          "sa",
          "Riyadh",
          "Riyadh",
          "12345",
        );

        log(
          'Payment Flow: Billing details -> name: $userName, email: $userEmail, phone: $userPhone',
          name: 'CheckoutFlow',
        );

        var config = PaymentSdkConfigurationDetails(
          profileId: paymentConfig['profileId'].toString(),
          serverKey: paymentConfig['serverKey'],
          clientKey: paymentConfig['clientKey'],
          cartId: paymentConfig['cartId'].toString(),
          cartDescription: paymentConfig['cartDescription'],
          merchantName: paymentConfig['merchantName'] ?? "Rahiq",
          screentTitle: AppLocalizations.of(context)!.pay_with_card,
          // Without this the SDK falls back to the device language, which can
          // differ from the language picked inside the app.
          locale: isAr ? PaymentSdkLocale.AR : PaymentSdkLocale.EN,
          amount: amount > 0 ? amount : 1.0,
          showBillingInfo: false,
          forceShippingInfo: false,
          currencyCode: paymentConfig['currency'] ?? "SAR",
          merchantCountryCode: "SA",
          billingDetails: billingDetails,
          shippingDetails: shippingDetails,
          alternativePaymentMethods: [],
          linkBillingNameWithCardHolderName: true,
          tokeniseType: PaymentSdkTokeniseType.NONE,
        );

        if (paymentMethod == 'APPLE_PAY') {
          config.merchantApplePayIndentifier =
              paymentConfig['applePayMerchantId'];
          config.simplifyApplePayValidation = true;
        } else if (paymentMethod == 'STC_PAY') {
          config.alternativePaymentMethods = [PaymentSdkAPms.STC_PAY];
        }

        log('Payment Flow: SDK Configuration generated.', name: 'CheckoutFlow');

        final theme = IOSThemeConfigurations();
        theme.logoImage = "assets/app_logo/logo.png";
        theme.primaryColor = "FFFFFF";
        theme.primaryColorDark = "FFFFFF";

        theme.secondaryColor = "1A6A8F";
        theme.secondaryColorDark = "1A6A8F";

        theme.buttonColor = "1A6A8F";
        theme.buttonColorDark = "1A6A8F";

        theme.backgroundColor = "F9FAFD";
        theme.backgroundColorDark = "F9FAFD";

        theme.primaryFontColor = "1e1e1e";
        theme.primaryFontColorDark = "1e1e1e";

        theme.secondaryFontColor = "1A6A8F";
        theme.secondaryFontColorDark = "1A6A8F";

        theme.buttonFontColor = "FFFFFF";
        theme.buttonFontColorDark = "FFFFFF";

        theme.titleFontColor = "1e1e1e";
        theme.titleFontColorDark = "1e1e1e";

        theme.strokeColor = "e1e1e1";
        theme.strokeColorDark = "e1e1e1";

        theme.inputFieldBackgroundColor = "FFFFFF";
        theme.inputFieldBackgroundColorDark = "FFFFFF";

        theme.placeholderColor = "a5a5a5";
        theme.placeholderColorDark = "a5a5a5";

        config.iOSThemeConfigurations = theme;

        void handlePaymentResult(dynamic event) async {
          log(
            'Payment Flow: Received PayTabs SDK event -> ${event.toString()}',
            name: 'CheckoutFlow',
          );
          if (event["status"] == "success") {
            var transactionDetails = event["data"];

            if (mounted) {
              setState(() {
                _isProcessingPayment = true;
              });
            }

            try {
              final txId = transactionDetails["transactionReference"];
              log(
                'Payment Flow: Calling verifyPayment with txId: $txId',
                name: 'CheckoutFlow',
              );
              final verifyResponse = await apiService.verifyPayment(
                paymentId: paymentId,
                transactionId: txId,
              );

              if (verifyResponse.data['success'] == true) {
                final paymentData =
                    verifyResponse.data['data'] ?? verifyResponse.data;
                final paymentStatus = paymentData['paymentStatus'];
                final verifyOrderNumber = paymentData['orderNumber'];

                if (paymentStatus == 'COMPLETED' ||
                    paymentStatus == 'PAID' ||
                    paymentStatus == 'SUCCESS') {
                  log(
                    'Payment Flow: verifyPayment successful. Status: $paymentStatus',
                    name: 'CheckoutFlow',
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentSuccessPage(
                        status: PaymentStatus.success,
                        isAr: isAr,
                        orderId:
                            verifyOrderNumber?.toString() ??
                            orderNumber?.toString() ??
                            orderId?.toString(),
                      ),
                    ),
                  );
                } else if (paymentStatus == 'FAILED' ||
                    paymentStatus == 'DECLINED' ||
                    paymentStatus == 'CANCELLED' ||
                    paymentStatus == 'PENDING') {
                  log(
                    'Payment Flow: verifyPayment failed. Status: $paymentStatus',
                    name: 'CheckoutFlow',
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentStatusPage(
                        status: PaymentStatus.failed,
                        message: AppLocalizations.of(context)!.payment_failed,
                        isAr: isAr,
                        onRetry: () => Navigator.pop(context),
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _isProcessingPayment = false;
                    });
                  }
                } else {
                  log(
                    'Payment Flow: verifyPayment returned pending/unknown status: $paymentStatus',
                    name: 'CheckoutFlow',
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentStatusPage(
                        status: PaymentStatus.pendingApproval,
                        isAr: isAr,
                      ),
                    ),
                  );
                }
              } else {
                log(
                  'Payment Flow: verifyPayment failed: ${verifyResponse.data['message']}',
                  name: 'CheckoutFlow',
                );
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentStatusPage(
                      status: PaymentStatus.failed,
                      message: verifyResponse.data['message'],
                      isAr: isAr,
                      onRetry: () => Navigator.pop(context),
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {
                    _isProcessingPayment = false;
                  });
                }
              }
            } catch (e) {
              log(
                'Payment Flow: verifyPayment API error: $e',
                name: 'CheckoutFlow',
              );

              bool is502Error = false;
              if (e is DioException) {
                if (e.response?.statusCode == 502) {
                  is502Error = true;
                }
              }

              if (is502Error) {
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentStatusPage(
                      status: PaymentStatus.serverError,
                      isAr: isAr,
                    ),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentStatusPage(
                      status: PaymentStatus.failed,
                      message: AppLocalizations.of(
                        context,
                      )!.error_verifying_payment,
                      isAr: isAr,
                      onRetry: () => Navigator.pop(context),
                    ),
                  ),
                );
              }

              if (mounted) {
                setState(() {
                  _isProcessingPayment = false;
                });
              }
            }
          } else if (event["status"] == "error") {
            if (mounted) {
              setState(() {
                _isProcessingPayment = false;
              });
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentStatusPage(
                  status: PaymentStatus.failed,
                  message: "${event["message"]}",
                  isAr: isAr,
                  onRetry: () => Navigator.pop(context),
                ),
              ),
            );
          } else if (event["status"] == "cancel" ||
              (event["status"] == "event" && event["message"] == "Cancelled")) {
            if (mounted) {
              setState(() {
                _isProcessingPayment = false;
              });
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentStatusPage(
                  status: PaymentStatus.cancelled,
                  isAr: isAr,
                  onRetry: () => Navigator.pop(context),
                ),
              ),
            );
          }
        }

        if (paymentMethod == 'APPLE_PAY') {
          FlutterPaytabsBridge.startApplePayPayment(
            config,
            handlePaymentResult,
          );
        } else if (paymentMethod == 'STC_PAY') {
          FlutterPaytabsBridge.startAlternativePaymentMethod(
            config,
            handlePaymentResult,
          );
        } else {
          FlutterPaytabsBridge.startCardPayment(config, handlePaymentResult);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
      log('Error processing payment: $e', error: e);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            status: PaymentStatus.failed,
            message: e.toString(),
            isAr: isAr,
            onRetry: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  Widget _buildSubscriptionDetails(bool isAr) {
    if (_checkoutData.subscription == null) return const SizedBox.shrink();

    final sub = _checkoutData.subscription;
    if (sub is! Map) return const SizedBox.shrink();

    final startDate = sub['startDate'] != null
        ? DateTime.tryParse(sub['startDate'].toString())?.toLocal()
        : null;
    final endDate = sub['endDate'] != null
        ? DateTime.tryParse(sub['endDate'].toString())?.toLocal()
        : null;
    final months = sub['months'] as int?;
    final dayOfMonth = sub['dayOfMonth'];
    final daysOfWeek = (sub['daysOfWeek'] as List<dynamic>?)?.cast<int>();

    // Infer type or get from plan if available
    String type = '';
    final plan = sub['plan'];
    final planName = plan['name'];
    final planNameAr = plan['nameAr'];
    final planFrequency = plan['frequency'];
    final occurrences = _checkoutData.occurrences;

    if (plan != null && plan is Map && planFrequency != null) {
      type = planFrequency.toString().toUpperCase();
    }

    final dateFormat = DateFormat(
      'dd MMMM yyyy',
      Localizations.localeOf(context).languageCode,
    );

    List<Widget> rows = [];

    if (type == 'EVERYDAY') {
      if (startDate != null && endDate != null) {
        // Calculate occurrences from startDate and endDate if not provided or 0
        if (plan != null && planName != null && planNameAr != null) {
          rows.add(
            _buildSubscriptionRow(
              AppLocalizations.of(context)!.subscription,
              '${isAr ? planNameAr : planName}',
            ),
          );
        }

        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.total_days,
            '$occurrences',
          ),
        );
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.start_date,
            dateFormat.format(startDate),
          ),
        );
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.end_date,
            dateFormat.format(endDate),
          ),
        );
      }
    } else if (type == 'ONCE_A_MONTH') {
      if (months != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.months,
            '$months',
          ),
        );
      }

      if (dayOfMonth != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.day_of_month,
            '$dayOfMonth',
          ),
        );
      }
      if (occurrences != 0) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.total_days,
            '$occurrences',
          ),
        );
      }
      if (startDate != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.start_date,
            dateFormat.format(startDate),
          ),
        );
      }
      if (endDate != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.end_date,
            dateFormat.format(endDate),
          ),
        );
      }
    } else if (type == 'ONCE_A_WEEK' || type == 'TWICE_A_WEEK') {
      if (months != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.months,
            '$months',
          ),
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
          0: 'الأحد',
        };
        final daysMapEn = {
          1: 'Mon',
          2: 'Tue',
          3: 'Wed',
          4: 'Thu',
          5: 'Fri',
          6: 'Sat',
          0: 'Sun',
        };
        final selectedDays = daysOfWeek
            .map((d) => isAr ? daysMapAr[d] : daysMapEn[d])
            .join(', ');
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.delivery_days,
            selectedDays,
          ),
        );
      }
      if (occurrences != 0) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.total_days,
            '$occurrences',
          ),
        );
      }
      if (startDate != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.start_date,
            dateFormat.format(startDate),
          ),
        );
      }
      if (endDate != null) {
        rows.add(
          _buildSubscriptionRow(
            AppLocalizations.of(context)!.end_date,
            dateFormat.format(endDate),
          ),
        );
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.subscription_details,
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
                color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
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
    bool canApplyCoupon = _checkoutData.canApplyCoupon ?? false;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = AppLocalizations.of(context)!.payment;
    final subtitle = AppLocalizations.of(context)!.final_review_and_payment;

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

    return AbsorbPointer(
      absorbing: _isProcessingPayment,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            extendBody: true,
            resizeToAvoidBottomInset: true,
            bottomNavigationBar: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: 16,
              ),
              child: BottomActionPill(
                isLoading: _isProcessingPayment,
                subtitleWidget: Text(
                  AppLocalizations.of(context)!.total_amount,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                titleWidget: Text(
                  "\u202A${AppLocalizations.of(context)!.sar_currency} ${_checkoutData.finalTotal.toStringAsFixed(2)}\u202C",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                buttonText: AppLocalizations.of(context)!.confirm_pay,
                onButtonTap: () => _confirmAndPay(context, isAr),
              ),
            ),

            body: CustomScrollView(
              physics: ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CustomAppBar(
                    hasBackgroundColor: true,
                    isStartAligned: true,
                    title: title,
                    subtitle: subtitle,
                    showBackButton: true,
                    onBackTap: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    transform: Matrix4.translationValues(0.0, -1.0, 0.0),
                    color: AppColors.buttonBlueDark,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          16,
                          24,
                          16,
                          MediaQuery.of(context).viewInsets.bottom > 0
                              ? 50
                              : 130,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              elevation: 2,
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 400 / 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    "assets/static_banners/payment_banner.jpeg",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPaymentMethods(isAr),
                            const SizedBox(height: 16),
                            _buildGiftCardSection(isAr),

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Card(
                                color: Colors.white,
                                elevation: 2,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.coupon_code,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (!canApplyCoupon)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.coupon_not_applicable,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      else if (_checkoutData.couponCode !=
                                              null &&
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
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: _isApplyingCoupon
                                                    ? const WaterLoadingIndicator(
                                                        size: 16,
                                                        waveColor1:
                                                            Colors.white,
                                                      )
                                                    : Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.remove,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: TextField(
                                                  inputFormatters: [
                                                    TextInputFormatter.withFunction(
                                                      (oldValue, newValue) =>
                                                          TextEditingValue(
                                                            text: newValue.text
                                                                .toUpperCase(),
                                                            selection: newValue
                                                                .selection,
                                                          ),
                                                    ),
                                                  ],
                                                  cursorColor:
                                                      AppColors.buttonBlueDark,
                                                  scrollPadding:
                                                      EdgeInsets.only(
                                                        bottom:
                                                            MediaQuery.of(
                                                                      context,
                                                                    )
                                                                    .viewInsets
                                                                    .bottom >
                                                                0
                                                            ? 160
                                                            : 20,
                                                      ),
                                                  controller: _couponController,
                                                  decoration: InputDecoration(
                                                    hintStyle: TextStyle(
                                                      color: AppColors.black
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .buttonBlueDark,
                                                          ),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .buttonBlueDark,
                                                          ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppColors
                                                                .buttonBlueDark,
                                                            width: 1.5,
                                                          ),
                                                    ),

                                                    hintText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.enter_coupon_code,
                                                  ),
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .buttonBlueDark,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ValueListenableBuilder<
                                              TextEditingValue
                                            >(
                                              valueListenable:
                                                  _couponController,
                                              builder: (context, value, child) {
                                                final bool isEmpty = value.text
                                                    .trim()
                                                    .isEmpty;
                                                return ElevatedButton(
                                                  onPressed:
                                                      (_isApplyingCoupon ||
                                                          isEmpty)
                                                      ? null
                                                      : () =>
                                                            _applyCoupon(isAr),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isEmpty
                                                        ? AppColors.grey
                                                        : AppColors
                                                              .buttonBlueDark,
                                                    disabledBackgroundColor:
                                                        AppColors.grey,
                                                    disabledForegroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 16.5,
                                                        ),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: _isApplyingCoupon
                                                      ? const WaterLoadingIndicator(
                                                          size: 16,
                                                          waveColor1:
                                                              Colors.white,
                                                        )
                                                      : Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.apply,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (_checkoutData.walletBalance > 0) ...[
                              const SizedBox(height: 16),
                              Card(
                                color: Colors.white,
                                elevation: 2,
                                margin: EdgeInsets.all(0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.use_wallet_balance,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .account_balance_wallet_outlined,
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "${AppLocalizations.of(context)!.available_colon} \u202A${AppLocalizations.of(context)!.sar_currency} ${_checkoutData.walletBalance.toStringAsFixed(2)}\u202C",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black,
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
                                            child: _isTogglingWallet
                                                ? const WaterLoadingIndicator(
                                                    size: 16,
                                                    waveColor1: Colors.white,
                                                  )
                                                : Text(
                                                    _checkoutData.useWallet
                                                        ? (AppLocalizations.of(
                                                            context,
                                                          )!.remove)
                                                        : (AppLocalizations.of(
                                                            context,
                                                          )!.apply),
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
                            ],
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              margin: EdgeInsets.all(0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.contribution_details,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...aggregatedProducts.values.map((sp) {
                                      return Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
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
                                              "\u202A${AppLocalizations.of(context)!.sar_currency} ${(sp.product.price * sp.quantity).toStringAsFixed(2)}\u202C",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    _buildSubscriptionDetails(isAr),
                                    const Divider(height: 16),
                                    _buildPriceRow(
                                      AppLocalizations.of(context)!.subtotal,
                                      _checkoutData.subTotal,
                                      isAr,
                                    ),
                                    if (_checkoutData.totalGiftCardFee > 0)
                                      _buildPriceRow(
                                        AppLocalizations.of(
                                          context,
                                        )!.gift_card_fees,
                                        _checkoutData.totalGiftCardFee,
                                        isAr,
                                      ),
                                    if ((_checkoutData.totalDeliveryFee >= 0
                                            ? _checkoutData.totalDeliveryFee
                                            : widget
                                                  .checkoutData
                                                  .totalDeliveryFee) >
                                        0)
                                      _buildPriceRow(
                                        AppLocalizations.of(
                                          context,
                                        )!.delivery_fee,
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
                                        AppLocalizations.of(context)!.vat,
                                        _checkoutData.vatAmount,
                                        isAr,
                                      ),
                                    if (_checkoutData.discountAmount > 0)
                                      _buildPriceRow(
                                        AppLocalizations.of(context)!.discount,
                                        -_checkoutData.discountAmount,
                                        isAr,
                                      ),
                                    if (_checkoutData.walletAmountUsed > 0)
                                      _buildPriceRow(
                                        AppLocalizations.of(
                                          context,
                                        )!.wallet_applied,
                                        -_checkoutData.walletAmountUsed,
                                        isAr,
                                      ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.total_amount,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "\u202A${AppLocalizations.of(context)!.sar_currency} ${_checkoutData.finalTotal.toStringAsFixed(2)}\u202C",
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
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessingPayment)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: WaterLoadingIndicator(
                    waveColor1: AppColors.buttonBlueDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGiftCardSection(bool isAr) {
    final itemsWithGiftCards = _checkoutData.items
        .where((item) => item.giftCard != null)
        .toList();
    final itemsWithoutGiftCards = _checkoutData.items
        .where((item) => item.giftCard == null)
        .toList();

    if (itemsWithGiftCards.isEmpty) {
      return _buildOriginalGiftCardSection(isAr);
    } else {
      return _buildGiftCardAddedSection(
        isAr,
        itemsWithGiftCards,
        itemsWithoutGiftCards,
      );
    }
  }

  Widget _buildGiftCardAddedSection(
    bool isAr,
    List<CheckoutItem> itemsWithGiftCards,
    List<CheckoutItem> itemsWithoutGiftCards,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.gift_card_added,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (NetworkMonitor.instance.status ==
                          NetworkStatus.offline) {
                        CustomSnackbar.show(
                          context: context,
                          message: AppLocalizations.of(context)!.internet_error,
                          isError: true,
                        );
                        return;
                      }
                      _showGiftCardsSheet(context, isAr, itemsWithGiftCards);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.buttonBlueDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.buttonBlueDark),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.show_gift_cards,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (itemsWithoutGiftCards.isNotEmpty &&
                    _checkoutData.items.length > 1) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final updatedCheckout = await Navigator.push<Checkout>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GiftCardPage(
                              checkoutData: _checkoutData,
                              isAr: isAr,
                            ),
                          ),
                        );

                        if (updatedCheckout != null) {
                          setState(() {
                            _checkoutData = updatedCheckout;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.add_gift_card,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftCardsSheet(
    BuildContext context,
    bool isAr,
    List<CheckoutItem> itemsWithGiftCards,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
                      child: Container(
                        width: 70,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.added_gift_cards,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.view_and_delete_gift_cards,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: itemsWithGiftCards.length == 1 ? 300 : 230,
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: itemsWithGiftCards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = itemsWithGiftCards[index];
                        final productName =
                            item.product?.localizedName(isAr) ?? '';
                        String extraInfo = item.location != null
                            ? (isAr
                                  ? item.location['nameAr']
                                  : item.location['name'])
                            : (item.city != null
                                  ? (isAr
                                        ? item.city['nameAr']
                                        : item.city['name'])
                                  : (item.category?.localizedLabel(isAr) ??
                                        ''));

                        final title = extraInfo.isNotEmpty
                            ? "$productName - $extraInfo"
                            : productName;
                        final qty = item.quantity;

                        final giftCardData =
                            item.giftCard != null && item.giftCard is Map
                            ? item.giftCard
                            : null;

                        final templateTitle =
                            ''; // Template title is not provided in the checkout response

                        final templateImage = giftCardData != null
                            ? giftCardData['generatedImage']
                            : null;

                        return SizedBox(
                          width: itemsWithGiftCards.length == 1
                              ? MediaQuery.of(context).size.width - 48
                              : (MediaQuery.of(context).size.width - 64) / 2.1,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${AppLocalizations.of(context)!.quantity}: $qty",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    if (templateTitle
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        templateTitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.buttonBlueDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (templateImage != null) ...[
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () => _showFullscreenImage(
                                              context,
                                              templateImage,
                                              isAr,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  CachedNetworkImage(
                                                    imageUrl: templateImage,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Shimmer.fromColors(
                                                          baseColor:
                                                              Colors.grey[300]!,
                                                          highlightColor:
                                                              Colors.grey[100]!,
                                                          child: Container(
                                                            color: Colors.white,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                          ),
                                                        ),
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                        ),
                                                  ),
                                                  Container(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.3),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.zoom_in,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Positioned.directional(
                                textDirection: isAr
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                top: 0,
                                end: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    await _removeGiftCard(item.id!, isAr);
                                    if (mounted) Navigator.pop(context);
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: WaterLoadingIndicator(size: 30),
                          ),
                        );
                        try {
                          final apiService = ApiService();
                          Response? lastResponse;
                          for (var item in itemsWithGiftCards) {
                            lastResponse = await apiService.removeGiftCard(
                              itemId: item.id!,
                            );
                          }
                          Navigator.pop(context); // close loader
                          Navigator.pop(context); // close sheet
                          if (lastResponse != null &&
                              lastResponse.data['success'] == true) {
                            setState(() {
                              _checkoutData = Checkout.fromJson(
                                lastResponse?.data['data'],
                              );
                            });
                          }
                        } catch (e) {
                          Navigator.pop(context); // close loader
                          CustomSnackbar.show(
                            context: context,
                            message: AppLocalizations.of(
                              context,
                            )!.error_removing_gift_card,
                            isError: true,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.delete_all_cards,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeGiftCard(String itemId, bool isAr) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: WaterLoadingIndicator(size: 30)),
    );
    try {
      final apiService = ApiService();
      final response = await apiService.removeGiftCard(itemId: itemId);
      Navigator.pop(context); // close loader

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _checkoutData = Checkout.fromJson(response.data['data']);
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loader
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.error_removing_gift_card,
          isError: true,
        );
      }
    }
  }

  void _showFullscreenImage(BuildContext context, String imageUrl, bool isAr) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,

                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalGiftCardSection(bool isAr) {
    return GestureDetector(
      onTap: () async {
        if (NetworkMonitor.instance.status == NetworkStatus.offline) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.internet_error,
            isError: true,
          );
          return;
        }

        final updatedCheckout = await Navigator.push<Checkout>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GiftCardPage(checkoutData: _checkoutData, isAr: isAr),
          ),
        );

        if (updatedCheckout != null) {
          setState(() {
            _checkoutData = updatedCheckout;
          });
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadiusDirectional.all(Radius.circular(20)),
              child: Container(
                // padding: EdgeInsetsDirectional.only(start: 24, end: 12),
                padding: EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  borderRadius: BorderRadiusDirectional.all(
                    Radius.circular(20),
                  ),
                ),
                child: Image.asset(
                  "assets/others/giftcard.png",
                  width: 155,

                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    size: 18,
                    Icons.card_giftcard_outlined,
                    color: AppColors.buttonBlueDark,
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.gift_your_loved_ones_the_blessing_of_providing_water_in_the_holiest_places,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: AppColors.buttonBlueDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        size: 12,
                        forwardArrowIcon(context),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
          ],
        ),
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
      padding: const EdgeInsetsDirectional.only(bottom: 8.0),
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
                "\u202A${AppLocalizations.of(context)!.sar_currency} ${value.toStringAsFixed(2)}\u202C",
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
                  AppLocalizations.of(context)!.free,
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
