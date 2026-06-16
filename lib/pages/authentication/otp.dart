import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/authentication/registration.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class OTP extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String? receivedOtp;
  const OTP({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    this.receivedOtp,
  });

  @override
  State<OTP> createState() => _OTPState();
}

class _OTPState extends State<OTP> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  String? _receivedOtp;
  bool _isLoadingOtp = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _receivedOtp = widget.receivedOtp;
    _isLoadingOtp = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _handleOtpPaste(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '').split('');
    if (digits.isEmpty) return;

    int currentIndex = startIndex;
    for (final digit in digits) {
      if (currentIndex >= _controllers.length) break;
      _controllers[currentIndex].text = digit;
      currentIndex++;
    }

    if (currentIndex < _focusNodes.length) {
      _focusNodes[currentIndex].requestFocus();
    } else {
      _focusNodes.last.unfocus();
    }

    setState(() {});
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: true,
        backgroundColor: AppColors.buttonBlueDark,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.enter_verification_code,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 16,
            top: 4,
            bottom: 4,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              highlightColor: Colors.transparent,
              icon: Icon(backArrowIcon(context)),
              color: Colors.black87,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Container(
                    padding: const EdgeInsetsDirectional.only(bottom: 30),
                    height: MediaQuery.of(context).size.height * 0.35,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Image.asset(
                      'assets/login/otp.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: MediaQuery.of(context).size.height * 0.35 - 50,
                    start: 24,
                    end: 24,
                    bottom: 40,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonBlueDark.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                          spreadRadius: -10,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.otp_sent_message,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${widget.countryCode}${widget.phoneNumber}",
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // OTP Display Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.buttonBlueDark.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.buttonBlueDark.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.your_verification_code,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingOtp)
                                SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.buttonBlueDark,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  _receivedOtp ?? 'N/A',
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: AppColors.buttonBlueDark,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          textDirection: TextDirection.ltr,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => Container(
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _focusNodes[index].hasFocus
                                      ? AppColors.buttonBlueDark
                                      : AppColors.indicatorGrey,
                                  width: _focusNodes[index].hasFocus ? 2 : 1,
                                ),
                              ),
                              child: TextField(
                                cursorColor: AppColors.buttonBlueDark,
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: "",
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (value) {
                                  if (value.length > 1) {
                                    _handleOtpPaste(value, index);
                                    return;
                                  }

                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _canResend
                                    ? AppLocalizations.of(
                                        context,
                                      )!.did_not_receive_code
                                    : AppLocalizations.of(
                                        context,
                                      )!.resend_code_in,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_canResend)
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(
                                          child: WaterLoadingIndicator(
                                            size: 30,
                                          ),
                                        ),
                                      );

                                      final response = await ApiService()
                                          .requestOtp(
                                            phoneNumber: widget.phoneNumber,
                                            countryCode: widget.countryCode,
                                          );

                                      if (!context.mounted) return;
                                      Navigator.pop(context); // Close loader

                                      if (response.statusCode == 200 &&
                                          response.data['success'] == true) {
                                        CustomSnackbar.show(
                                          context: context,
                                          message: AppLocalizations.of(
                                            context,
                                          )!.otp_sent_successfully,
                                        );
                                        _startTimer();
                                        setState(() {
                                          _receivedOtp =
                                              response.data['data']?['otp']
                                                  ?.toString() ??
                                              'N/A';
                                        });
                                      } else {
                                        CustomSnackbar.show(
                                          context: context,
                                          message:
                                              response.data['message'] ??
                                              AppLocalizations.of(
                                                context,
                                              )!.failed_to_resend_otp,
                                          isError: true,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Close loader
                                      }
                                      String errorMessage =
                                          'Error: ${e.toString()}';
                                      if (e is DioException &&
                                          e.response?.statusCode == 429) {
                                        errorMessage = AppLocalizations.of(
                                          context,
                                        )!.too_many_attempts;
                                      }
                                      CustomSnackbar.show(
                                        context: context,
                                        message: errorMessage,
                                        isError: true,
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.resend,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.buttonBlueDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  _formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.buttonBlueDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isVerifying
                                ? null
                                : () async {
                                    final otp = _controllers
                                        .map((c) => c.text)
                                        .join();
                                    if (otp.length < 6) {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.enter_valid_otp,
                                      );
                                      return;
                                    }

                                    setState(() => _isVerifying = true);
                                    try {
                                      final response = await ApiService().verifyOtp(
                                        countryCode: widget.countryCode,
                                        phoneNumber: widget.phoneNumber,
                                        otp: otp,
                                        deviceType:
                                            'ANDROID', // Ideally, get this from device_info_plus
                                      );

                                      if (!context.mounted) return;
                                      setState(() => _isVerifying = false);

                                      if (response.statusCode == 200 &&
                                          response.data['success'] == true) {
                                        final data = response.data['data'];
                                        if (data['userExists'] == true) {
                                          // User exists, login successful
                                          CustomSnackbar.show(
                                            context: context,
                                            message: AppLocalizations.of(
                                              context,
                                            )!.login_successful,
                                          );
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomeScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        } else {
                                          final regToken =
                                              data['registrationToken'] ?? '';
                                          await AuthStorage.saveRegistrationToken(
                                            regToken,
                                          );

                                          if (!context.mounted) return;
                                          // User doesn't exist, go to registration
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Registration(
                                                    phoneNumber:
                                                        widget.phoneNumber,
                                                    countryCode:
                                                        widget.countryCode,
                                                    registrationToken: regToken,
                                                  ),
                                            ),
                                          );
                                        }
                                      } else {
                                        CustomSnackbar.show(
                                          context: context,
                                          message:
                                              response.data['message'] ??
                                              AppLocalizations.of(
                                                context,
                                              )!.verification_failed,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() => _isVerifying = false);
                                      }
                                      if (!context.mounted) return;
                                      String errorMessage = AppLocalizations.of(
                                        context,
                                      )!.verification_failed;
                                      if (e is DioException) {
                                        if (e.response?.statusCode == 401) {
                                          errorMessage = AppLocalizations.of(
                                            context,
                                          )!.invalid_otp;
                                        } else if (e.response?.data != null &&
                                            e.response!.data['message'] !=
                                                null) {
                                          errorMessage =
                                              e.response!.data['message'];
                                        }
                                      }
                                      CustomSnackbar.show(
                                        context: context,
                                        message: errorMessage,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBlueDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35),
                              ),
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: WaterLoadingIndicator(
                                      dropletBackgroundColor:
                                          AppColors.buttonBlueDark,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.continue_btn,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
