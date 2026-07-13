import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:raheeq_main/common_widgets/language_switch.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:raheeq_main/pages/authentication/otp.dart';
import 'package:raheeq_main/pages/authentication/registration.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:dio/dio.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isLoading = false;
  Country _selectedCountry = Country(
    phoneCode: '966',
    countryCode: 'SA',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Saudi Arabia',
    example: '501234567',
    displayName: 'Saudi Arabia',
    displayNameNoCountryCode: 'Saudi Arabia',
    e164Key: '',
  );

  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    log('Tapped Google Sign-In button');
    try {
      final google_sign_in.GoogleSignIn instance =
          google_sign_in.GoogleSignIn.instance;
      await instance.initialize(
        serverClientId:
            '579658096080-e8oiqp649otjnrbs4h9rijcp2hnhlme4.apps.googleusercontent.com',
      );

      log('Starting Google Sign-In authentication...');
      final google_sign_in.GoogleSignInAccount account = await instance
          .authenticate();
      log('Google Sign-In Account retrieved: ${account.email}');

      final google_sign_in.GoogleSignInAuthentication auth =
          account.authentication;
      if (auth.idToken != null) {
        log('Google Sign-In ID Token retrieved successfully');
        final names = account.displayName?.split(' ') ?? [];
        final firstName = names.isNotEmpty ? names.first : null;
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : null;
        await _authenticateSocial(
          'Google',
          auth.idToken!,
          email: account.email,
          firstName: firstName,
          lastName: lastName,
        );
      } else {
        log('Google Sign-In failed: idToken is null');
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(
              context,
            )!.failed_to_retrieve_google_id_token,
            isError: true,
          );
        }
      }
    } catch (error) {
      log('Google Sign-In Error: $error');
      if (mounted) {
        String errorMessage = 'Failed to sign in with Google: $error';
        if (error.toString().toLowerCase().contains('cancel')) {
          errorMessage = 'Google sign in was cancelled';
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    log('Tapped Apple Sign-In button');
    try {
      log('Starting Apple Sign-In authentication...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      log(
        'Apple Sign-In Credential retrieved for user: ${credential.email ?? "Unknown Email"}',
      );

      if (credential.identityToken != null) {
        log('Apple Sign-In Identity Token retrieved successfully');
        await _authenticateSocial(
          'Apple',
          credential.identityToken!,
          email: credential.email,
          firstName: credential.givenName,
          lastName: credential.familyName,
        );
      } else {
        log('Apple Sign-In failed: identityToken is null');
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(
              context,
            )!.failed_to_retrieve_apple_identity_token,
            isError: true,
          );
        }
      }
    } catch (error) {
      log('Apple Sign-In Error: $error');
      if (mounted) {
        String errorMessage = 'Failed to sign in with Apple: $error';
        if (error.toString().toLowerCase().contains('cancel')) {
          errorMessage = 'Apple sign in was cancelled';
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    if (provider == 'Google') {
      await _handleGoogleSignIn();
    } else if (provider == 'Apple') {
      await _handleAppleSignIn();
    }
  }

  Future<void> _authenticateSocial(
    String provider,
    String idToken, {
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: WaterLoadingIndicator(size: 30)),
    );

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      String? deviceId;
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isIOS) {
          final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else if (Platform.isAndroid) {
          final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        }
      } catch (e) {
        log('Failed to get device info: $e');
      }

      final apiService = ApiService();
      final response = provider == 'Google'
          ? await apiService.googleLogin(
              idToken: idToken,
              fcmToken: fcmToken,
              deviceType: Platform.isIOS ? 'IOS' : 'ANDROID',
              deviceId: deviceId ?? 'unknown_device_id',
            )
          : await apiService.appleLogin(
              idToken: idToken,
              fcmToken: fcmToken,
              deviceType: Platform.isIOS ? 'IOS' : 'ANDROID',
              deviceId: deviceId ?? 'unknown_device_id',
            );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        if (resData['userExists'] == true) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.login_successful,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          final regToken = resData['registrationToken'] ?? '';
          await AuthStorage.saveRegistrationToken(regToken);

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Registration(
                phoneNumber: '',
                countryCode: '',
                registrationToken: regToken,
                isSocialLogin: true,
                email: email,
                firstName: firstName,
                lastName: lastName,
              ),
            ),
          );
        }
      } else {
        CustomSnackbar.show(
          context: context,
          message:
              response.data['message'] ??
              AppLocalizations.of(context)!.authentication_failed,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      String errorMessage = AppLocalizations.of(context)!.authentication_failed;
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      CustomSnackbar.show(
        context: context,
        message: errorMessage,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.buttonBlueDark,
        shape: Border.all(width: 0, color: AppColors.buttonBlueDark),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.login,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 24),
            child: LanguageSwitchButton(isFromLogin: true),
          ),
        ],
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
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                      bottom: 35,
                    ),
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
                      'assets/login/login.png',
                      fit: BoxFit.contain,
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
                    padding: const EdgeInsets.all(8),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Phone Input Section
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: AppColors.indicatorGrey,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme: TextSelectionThemeData(
                                      cursorColor: AppColors.buttonBlueDark,
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) => InkWell(
                                      onTap: () {
                                        showCountryPicker(
                                          favorite: [
                                            "SA",
                                            "AE",
                                            "KW",
                                            "BH",
                                            "QA",
                                            "OM",
                                            "SD",
                                          ],
                                          context: context,
                                          showPhoneCode: true,
                                          onSelect: (Country country) {
                                            setState(() {
                                              _selectedCountry = country;
                                            });
                                          },
                                          countryListTheme: CountryListThemeData(
                                            bottomSheetHeight:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.7,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(30),
                                                  topRight: Radius.circular(30),
                                                ),

                                            inputDecoration: InputDecoration(
                                              hintText: AppLocalizations.of(
                                                context,
                                              )!.search,
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.grey[200],
                                            backgroundImage: NetworkImage(
                                              "https://flagcdn.com/w80/${_selectedCountry.countryCode.toLowerCase()}.png",
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              "+${_selectedCountry.phoneCode}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    cursorColor: AppColors.buttonBlueDark,
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.enter_phone,
                                      hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.otp_message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_phoneController.text.trim().isEmpty) {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.enter_phone,
                                        isError: true,
                                      );
                                      return;
                                    }

                                    if (!RegExp(
                                      r'^\d+$',
                                    ).hasMatch(_phoneController.text.trim())) {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.invalid_phone_number,
                                        isError: true,
                                      );
                                      return;
                                    }
                                    try {
                                      final phone = PhoneNumber.parse(
                                        '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
                                      );
                                      if (!phone.isValid(
                                            type: PhoneNumberType.mobile,
                                          ) &&
                                          !phone.isValid()) {
                                        CustomSnackbar.show(
                                          context: context,
                                          message: AppLocalizations.of(
                                            context,
                                          )!.enter_valid_number_gc,
                                          isError: true,
                                        );
                                        return;
                                      }
                                    } catch (e) {
                                      CustomSnackbar.show(
                                        context: context,
                                        message: AppLocalizations.of(
                                          context,
                                        )!.invalid_phone_format,
                                        isError: true,
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);
                                    try {
                                      final response = await ApiService()
                                          .requestOtp(
                                            phoneNumber: _phoneController.text,
                                            countryCode:
                                                '+${_selectedCountry.phoneCode}',
                                          );

                                      if (!context.mounted) return;
                                      setState(() => _isLoading = false);

                                      if (response.statusCode == 200 &&
                                          response.data['success'] == true) {
                                        final receivedOtp = response
                                            .data['data']?['otp']
                                            ?.toString();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OTP(
                                              phoneNumber:
                                                  _phoneController.text,
                                              countryCode:
                                                  '+${_selectedCountry.phoneCode}',
                                              receivedOtp: receivedOtp,
                                            ),
                                          ),
                                        );
                                      } else {
                                        CustomSnackbar.show(
                                          context: context,
                                          message:
                                              response.data['message'] ??
                                              AppLocalizations.of(
                                                context,
                                              )!.failed_to_send_otp,
                                          isError: true,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() => _isLoading = false);
                                      }
                                      String errorMessage = AppLocalizations.of(
                                        context,
                                      )!.failed_to_send_otp;
                                      if (e is ApiDioException) {
                                        if (e.type ==
                                            DioExceptionType.connectionError) {
                                          // Internet interceptor already showed a snackbar
                                          return;
                                        }
                                        errorMessage = e.apiMessage;
                                      } else if (e is DioException) {
                                        if (e.type ==
                                            DioExceptionType.connectionError) {
                                          return;
                                        }
                                        if (e.response?.statusCode == 429) {
                                          errorMessage = AppLocalizations.of(
                                            context,
                                          )!.too_many_attempts;
                                        } else if (e.response?.data is Map &&
                                            e.response?.data['message'] !=
                                                null) {
                                          errorMessage =
                                              e.response?.data['message'];
                                        }
                                      }
                                      CustomSnackbar.show(
                                        context: context,
                                        message: errorMessage,
                                        isError: true,
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
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: WaterLoadingIndicator(
                                      waveColor1: AppColors.buttonBlueDark,
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
                        const SizedBox(height: 32),
                        // Divider Section
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 0.8,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.or,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Social Login Buttons
                        _buildSocialButton(
                          icon: FontAwesomeIcons.google,
                          label: AppLocalizations.of(context)!.google_signin,
                          onPressed: () => _handleSocialLogin('Google'),
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                          borderColor: Colors.grey[300],
                        ),
                        if (Platform.isIOS) ...{
                          const SizedBox(height: 14),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.apple,
                            label: AppLocalizations.of(context)!.apple_signin,
                            onPressed: () => _handleSocialLogin('Apple'),
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                          ),
                        },
                        const SizedBox(height: 32),
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

  Widget _buildSocialButton({
    required FaIconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 20, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
