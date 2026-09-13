import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:raheeq_main/utils/otp_autofill.dart';
import 'package:raheeq_main/utils/digits.dart';
import 'package:raheeq_main/utils/phone_formatter.dart';
import 'package:country_picker/country_picker.dart';
import 'package:raheeq_main/common_widgets/language_switch.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:raheeq_main/pages/authentication/otp.dart';
import 'package:raheeq_main/pages/authentication/registration.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/storage/app_storage.dart';
import 'package:raheeq_main/utils/apple_id_token.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
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
  String? _socialLoadingProvider;
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
  final TapGestureRecognizer _termsTapRecognizer = TapGestureRecognizer();

  @override
  void dispose() {
    _phoneController.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openTermsAndConditions() async {
    final url = Uri.parse("https://suqyarahiq.com/terms-and-conditions.html");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildTermsNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          children: [
            TextSpan(text: l10n.login_terms_prefix),
            TextSpan(
              text: l10n.terms_conditions,
              style: const TextStyle(
                color: AppColors.buttonBlueDark,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.buttonBlueDark,
                fontWeight: FontWeight.w600,
              ),
              recognizer: _termsTapRecognizer..onTap = _openTermsAndConditions,
            ),
            TextSpan(text: l10n.login_terms_suffix),
          ],
        ),
      ),
    );
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
        final l10n = AppLocalizations.of(context)!;
        final isCancelled =
            error is google_sign_in.GoogleSignInException &&
            error.code == google_sign_in.GoogleSignInExceptionCode.canceled;
        CustomSnackbar.show(
          context: context,
          message: isCancelled
              ? l10n.google_sign_in_cancelled
              : l10n.failed_to_sign_in_google,
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

      if (credential.identityToken == null) {
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
        return;
      }

      // Apple decides "first authorization" per Apple ID + app, not per account
      // in our backend. A customer who registered with Apple, deleted their
      // account, and now signs up again is a new registration to us but a
      // repeat authorization to Apple: the credential comes back with email and
      // name null, and Apple shows no sheet offering to re-share them. Same for
      // anyone who simply abandoned registration the first time round.
      //
      // Registration shows the email read-only, so an unresolved email there is
      // a dead end. AppleProfile falls back to the identity token, which does
      // carry the address on every sign-in, then to what we cached earlier.
      final profile = AppleProfile.resolve(
        credentialEmail: credential.email,
        credentialGivenName: credential.givenName,
        credentialFamilyName: credential.familyName,
        identityToken: credential.identityToken,
        cached: AppStorage.appleProfile(credential.userIdentifier ?? ""),
      );
      final email = profile.email;
      final firstName = profile.firstName;
      final lastName = profile.lastName;

      // Persist whatever this sign-in taught us, so the next one can fall back
      // to it. Guarded on userIdentifier: without a key there is nothing safe
      // to file the details under.
      if (credential.userIdentifier != null) {
        await AppStorage.saveAppleProfile(
          userIdentifier: credential.userIdentifier!,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
      }

      log(
        'Apple Sign-In credential retrieved '
        '(email: ${email ?? "none"}, name: ${firstName ?? "none"} '
        '${lastName ?? ""}, emailFromCredential: ${credential.email != null})',
      );

      await _authenticateSocial(
        'Apple',
        credential.identityToken!,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (error) {
      log('Apple Sign-In Error: $error');
      if (mounted) {
        // Cancelling is a deliberate user action rather than a failure, so it
        // gets its own message. SignInWithApple surfaces it as a canceled
        // authorization code.
        final l10n = AppLocalizations.of(context)!;
        final isCancelled =
            error is SignInWithAppleAuthorizationException &&
            error.code == AuthorizationErrorCode.canceled;
        CustomSnackbar.show(
          context: context,
          message: isCancelled
              ? l10n.apple_sign_in_cancelled
              : l10n.failed_to_sign_in_apple,
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _socialLoadingProvider = provider;
    });
    try {
      if (provider == 'Google') {
        await _handleGoogleSignIn();
      } else if (provider == 'Apple') {
        await _handleAppleSignIn();
      }
    } finally {
      if (mounted) {
        setState(() {
          _socialLoadingProvider = null;
        });
      }
    }
  }

  Future<void> _authenticateSocial(
    String provider,
    String idToken, {
    String? email,
    String? firstName,
    String? lastName,
  }) async {
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

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        if (resData['userExists'] == true) {
          // Reaching the home screen is confirmation enough — no success
          // snackbar, matching the OTP path.
          Navigator.pushAndRemoveUntil(
            context,
            HomeScreen.route(),
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
      resizeToAvoidBottomInset: false,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'assets/login/new_login.png',
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
                                          color: Colors.black.withValues(
                                            alpha: 0.02,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            textSelectionTheme:
                                                TextSelectionThemeData(
                                                  cursorColor:
                                                      AppColors.buttonBlueDark,
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
                                                      _selectedCountry =
                                                          country;
                                                      final formatted =
                                                          GlobalPhoneFormatter.formatText(
                                                            _phoneController
                                                                .text,
                                                          );
                                                      if (_phoneController
                                                              .text !=
                                                          formatted) {
                                                        _phoneController
                                                            .value = TextEditingValue(
                                                          text: formatted,
                                                          selection:
                                                              TextSelection.collapsed(
                                                                offset:
                                                                    formatted
                                                                        .length,
                                                              ),
                                                        );
                                                      }
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
                                                          topLeft:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                    inputDecoration: InputDecoration(
                                                      hintText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.search,
                                                      prefixIcon: const Icon(
                                                        Icons.search,
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: AppColors
                                                              .buttonBlueDark,
                                                        ),
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: AppColors
                                                              .buttonBlueDark,
                                                        ),
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Colors.grey
                                                              .withValues(
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
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          60,
                                                        ),

                                                    child: Container(
                                                      height: 36,
                                                      width: 60,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: CachedNetworkImage(
                                                        fit: BoxFit.cover,
                                                        imageUrl:
                                                            "https://flagcdn.com/w80/${_selectedCountry.countryCode.toLowerCase()}.png",
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => WaterLoadingIndicator(
                                                              size: 16,
                                                              waveColor1: AppColors
                                                                  .buttonBlueDark,
                                                            ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => const Icon(
                                                              Icons.error,
                                                              size: 16,
                                                              color: Colors.red,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Directionality(
                                                    textDirection:
                                                        TextDirection.ltr,
                                                    child: Text(
                                                      "+${_selectedCountry.phoneCode}",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                            cursorColor:
                                                AppColors.buttonBlueDark,
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              const LatinDigitsInputFormatter(),
                                              GlobalPhoneFormatter(
                                                onCountryDetected: (country) {
                                                  if (mounted) {
                                                    setState(
                                                      () => _selectedCountry =
                                                          country,
                                                    );
                                                  }
                                                },
                                              ),
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              hintText: AppLocalizations.of(
                                                context,
                                              )!.enter_phone,
                                              hintStyle: TextStyle(
                                                color: AppColors.black
                                                    .withValues(alpha: 0.8),
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.black,
                                              fontSize: 14,
                                            ),
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
                                    onPressed:
                                        (_isLoading ||
                                            _socialLoadingProvider != null)
                                        ? null
                                        : () async {
                                            String phoneText = _phoneController
                                                .text
                                                .trim();
                                            if (phoneText.isEmpty) {
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
                                            ).hasMatch(phoneText)) {
                                              CustomSnackbar.show(
                                                context: context,
                                                message: AppLocalizations.of(
                                                  context,
                                                )!.invalid_phone_number,
                                                isError: true,
                                              );
                                              return;
                                            }

                                            // The field keeps the trunk `0` the
                                            // user typed; the API and
                                            // `PhoneNumber.parse` both want the
                                            // number without it.
                                            final apiPhoneText =
                                                GlobalPhoneFormatter.toNationalNumber(
                                                  phoneText,
                                                  _selectedCountry,
                                                );

                                            if (_selectedCountry.phoneCode ==
                                                '966') {
                                              if (phoneText.startsWith('0') &&
                                                  phoneText.length != 10) {
                                                CustomSnackbar.show(
                                                  context: context,
                                                  message: AppLocalizations.of(
                                                    context,
                                                  )!.enter_valid_number_gc,
                                                  isError: true,
                                                );
                                                return;
                                              } else if (phoneText.startsWith(
                                                    '5',
                                                  ) &&
                                                  phoneText.length != 9) {
                                                CustomSnackbar.show(
                                                  context: context,
                                                  message: AppLocalizations.of(
                                                    context,
                                                  )!.enter_valid_number_gc,
                                                  isError: true,
                                                );
                                                return;
                                              } else if (!phoneText.startsWith(
                                                    '0',
                                                  ) &&
                                                  !phoneText.startsWith('5')) {
                                                CustomSnackbar.show(
                                                  context: context,
                                                  message: AppLocalizations.of(
                                                    context,
                                                  )!.enter_valid_number_gc,
                                                  isError: true,
                                                );
                                                return;
                                              }
                                            } else {
                                              try {
                                                final phone = PhoneNumber.parse(
                                                  '+${_selectedCountry.phoneCode}$apiPhoneText',
                                                );
                                                if (!phone.isValid(
                                                      type: PhoneNumberType
                                                          .mobile,
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
                                            }

                                            setState(() => _isLoading = true);
                                            try {
                                              // Arm the SMS retriever before the OTP is
                                              // requested. It only matches messages
                                              // that arrive after it starts listening,
                                              // so arming it on the OTP screen (after
                                              // this request returns and the route is
                                              // pushed) loses the race whenever the SMS
                                              // beats the navigation.
                                              unawaited(
                                                OtpAutofill.instance.arm(),
                                              );

                                              final response =
                                                  await ApiService().requestOtp(
                                                    phoneNumber: apiPhoneText,
                                                    countryCode:
                                                        '+${_selectedCountry.phoneCode}',
                                                  );
                                              log("context not mounted");
                                              if (!context.mounted) return;
                                              log("context mounted");
                                              if (response.statusCode == 200 &&
                                                  response.data['success'] ==
                                                      true) {
                                                // final receivedOtp = response
                                                //     .data['data']?['otp']
                                                //     ?.toString();
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => OTP(
                                                      phoneNumber: apiPhoneText,
                                                      countryCode:
                                                          '+${_selectedCountry.phoneCode}',
                                                      // receivedOtp: receivedOtp,
                                                    ),
                                                  ),
                                                );
                                                log("otp sent");
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                }
                                                log(
                                                  "otp sent and state changed",
                                                );
                                              } else {
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                }
                                                log(
                                                  "otp not sent and state changed",
                                                );
                                                CustomSnackbar.show(
                                                  context: context,
                                                  message:
                                                      response
                                                          .data['message'] ??
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.failed_to_send_otp,
                                                  isError: true,
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                setState(
                                                  () => _isLoading = false,
                                                );
                                              }
                                              String errorMessage =
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.failed_to_send_otp;
                                              if (e is DioException) {
                                                if (e.type ==
                                                    DioExceptionType
                                                        .connectionError) {
                                                  CustomSnackbar.show(
                                                    context: context,
                                                    isError: true,
                                                    message:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.internet_error,
                                                  );
                                                  return;
                                                } else if (e
                                                        .response
                                                        ?.statusCode ==
                                                    429) {
                                                  errorMessage =
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.too_many_attempts;
                                                } else if (e.response?.data
                                                        is Map &&
                                                    e
                                                            .response
                                                            ?.data['message'] !=
                                                        null) {
                                                  errorMessage = e
                                                      .response
                                                      ?.data['message'];
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
                                      disabledBackgroundColor:
                                          AppColors.buttonBlueDark,
                                      disabledForegroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(35),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: WaterLoadingIndicator(
                                              waveColor1: AppColors.white,
                                            ),
                                          )
                                        : Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.continue_btn,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
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
                                  label: "Sign in with Google",
                                  onPressed: () => _handleSocialLogin('Google'),
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black87,
                                  borderColor: Colors.grey[300],
                                  isLoading: _socialLoadingProvider == 'Google',
                                ),
                                if (Platform.isIOS) ...{
                                  const SizedBox(height: 14),
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.apple,
                                    label: "Sign in with Apple",
                                    onPressed: () =>
                                        _handleSocialLogin('Apple'),
                                    backgroundColor: Colors.black,
                                    textColor: Colors.white,
                                    isLoading:
                                        _socialLoadingProvider == 'Apple',
                                  ),
                                },
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildTermsNotice(context),
                  ],
                ),
              ),
            );
          },
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
    bool isLoading = false,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isLoading || _socialLoadingProvider != null)
              ? null
              : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            disabledBackgroundColor: backgroundColor,
            disabledForegroundColor: textColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
              side: borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: WaterLoadingIndicator(
                    waveColor1: AppColors.buttonBlueDark,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
