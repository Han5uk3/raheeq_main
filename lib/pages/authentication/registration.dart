import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/language_switch.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/authentication/login.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class Registration extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String registrationToken;
  const Registration({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.registrationToken,
  });

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Keys to access individual FormField states so we can query `hasError`
  final Map<TextEditingController, GlobalKey<FormFieldState<String>>>
  _fieldKeys = {};
  final GlobalKey<FormFieldState<String>> _genderFieldKey =
      GlobalKey<FormFieldState<String>>();

  String? _selectedGender;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '${widget.countryCode}${widget.phoneNumber}';
    // Initialize field keys for each controller
    _fieldKeys[_firstNameController] = GlobalKey<FormFieldState<String>>();
    _fieldKeys[_lastNameController] = GlobalKey<FormFieldState<String>>();
    _fieldKeys[_emailController] = GlobalKey<FormFieldState<String>>();
    _fieldKeys[_phoneController] = GlobalKey<FormFieldState<String>>();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: AppColors.buttonBlueDark,
        centerTitle: true,
        toolbarHeight: 80,
        title: Text(
          AppLocalizations.of(context)!.complete_profile,
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
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              ),
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 24),
            child: LanguageSwitchButton(isFromLogin: false),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isRegistering,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      top: MediaQuery.of(context).size.height * 0.05,
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
                              alpha: 0.1,
                            ),
                            blurRadius: 50,
                            offset: const Offset(0, 25),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Picture Section
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.buttonBlueDark
                                            .withValues(alpha: 0.1),
                                        width: 4,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Color(0xFFF0F4F8),
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  PositionedDirectional(
                                    bottom: 0,
                                    end: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.buttonBlueDark,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildTextField(
                              controller: _firstNameController,
                              label: AppLocalizations.of(context)!.first_name,
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_first_name,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _lastNameController,
                              label: AppLocalizations.of(context)!.last_name,
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_last_name,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label:
                                  "${AppLocalizations.of(context)!.email_address} (${AppLocalizations.of(context)!.optional})",
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_email_optional_hint,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isEmail: true,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: AppLocalizations.of(context)!.phone_number,
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_phone_number_hint,
                              icon: Icons.phone_outlined,
                              enabled: false, // Pre-filled and locked
                              isRtl:
                                  Localizations.localeOf(
                                    context,
                                  ).languageCode ==
                                  'ar',
                            ),

                            const SizedBox(height: 16),
                            _buildGenderDropdown(),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRegistering
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _isRegistering = true);
                                          try {
                                            final response = await ApiService()
                                                .register(
                                                  countryCode:
                                                      widget.countryCode,
                                                  phoneNumber: widget
                                                      .phoneNumber
                                                      .replaceAll(
                                                        widget.countryCode,
                                                        '',
                                                      )
                                                      .trim(), // Ensure pure phone number
                                                  email: _emailController.text
                                                      .trim(),
                                                  firstName:
                                                      _firstNameController.text
                                                          .trim(),
                                                  lastName: _lastNameController
                                                      .text
                                                      .trim(),
                                                  gender:
                                                      _selectedGender
                                                          ?.toUpperCase() ??
                                                      'MALE',
                                                  deviceType: Platform.isIOS
                                                      ? 'IOS'
                                                      : 'ANDROID',
                                                  registrationToken:
                                                      widget.registrationToken,
                                                );

                                            if (!context.mounted) return;
                                            setState(
                                              () => _isRegistering = false,
                                            );

                                            if ((response.statusCode == 200 ||
                                                    response.statusCode ==
                                                        201) &&
                                                response.data['success'] ==
                                                    true) {
                                              // ScaffoldMessenger.of(
                                              //   context,
                                              // ).showSnackBar(
                                              //   const SnackBar(
                                              //     content: Text(
                                              //       'Registration Successful!',
                                              //     ),
                                              //   ),
                                              // );
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomeScreen(),
                                                ),
                                                (route) => false,
                                              );
                                            } else {
                                              CustomSnackbar.show(
                                                context: context,
                                                message:
                                                    response.data['message'] ??
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.registration_failed,
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              setState(
                                                () => _isRegistering = false,
                                              );
                                            }
                                            String errorMessage =
                                                AppLocalizations.of(
                                                  context,
                                                )!.registration_failed;
                                            try {
                                              if (e is DioException &&
                                                  e.response?.data != null) {
                                                final data = e.response!.data;
                                                if (data is Map) {
                                                  if (data['details'] != null &&
                                                      data['details'] is List &&
                                                      data['details']
                                                          .isNotEmpty) {
                                                    errorMessage =
                                                        data['details'][0]['message']
                                                            ?.toString() ??
                                                        data['message']
                                                            ?.toString() ??
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.validation_error;
                                                  } else if (data['message'] !=
                                                      null) {
                                                    errorMessage =
                                                        data['message']
                                                            .toString();
                                                  }
                                                }
                                              } else if (e.toString().contains(
                                                'DioException',
                                              )) {
                                                // Fallback if type check somehow fails
                                                errorMessage = AppLocalizations.of(
                                                  context,
                                                )!.validation_error_check_inputs;
                                              } else {
                                                errorMessage =
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.error_msg(e.toString());
                                              }
                                            } catch (_) {
                                              errorMessage =
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.error_msg(e.toString());
                                            }

                                            CustomSnackbar.show(
                                              context: context,
                                              message: errorMessage,
                                              isError: true,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonBlueDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                                child: _isRegistering
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: WaterLoadingIndicator(
                                          dropletBackgroundColor:
                                              AppColors.buttonBlueDark,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context)!.register,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    bool isEmail = false,
    bool isRtl = false,
    bool isOptional = false,
  }) {
    final fieldKey = _fieldKeys[controller];
    final hasError = fieldKey?.currentState?.hasError == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsetsDirectional.only(bottom: hasError == true ? 8 : 0),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.indicatorGrey),
          ),
          child: TextFormField(
            key: fieldKey,
            cursorColor: AppColors.buttonBlueDark,
            textAlign: isRtl ? TextAlign.end : TextAlign.start,
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            textDirection: isRtl ? TextDirection.ltr : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: AppColors.buttonBlueDark.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: false,
            ),
            onChanged: (value) {
              // Validate only this field and update UI immediately
              fieldKey?.currentState?.validate();
              setState(() {});
            },
            validator: (value) {
              final trimmedValue = value?.trim() ?? '';
              if (trimmedValue.isEmpty) {
                if (isOptional) return null;
                return AppLocalizations.of(context)!.field_required;
              }
              if (isEmail) {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(trimmedValue)) {
                  return AppLocalizations.of(context)!.enter_valid_email;
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final hasError = _selectedGender == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.gender,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsetsDirectional.only(bottom: hasError == true ? 8 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.indicatorGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              isExpanded: true,
              initialValue: _selectedGender,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              hint: Text(
                AppLocalizations.of(context)!.select_gender,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              items:
                  [
                        {
                          'label': AppLocalizations.of(context)!.male,
                          'value': 'Male',
                        },
                        {
                          'label': AppLocalizations.of(context)!.female,
                          'value': 'Female',
                        },
                        {
                          'label': AppLocalizations.of(context)!.other_gender,
                          'value': 'Other',
                        },
                      ]
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(
                            item['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
                // Validate gender field specifically and refresh UI
                _genderFieldKey.currentState?.validate();
                setState(() {});
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.wc_outlined,
                  size: 20,
                  color: AppColors.buttonBlueDark.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: false,
                errorMaxLines: 2,
              ),
              validator: (value) => value == null
                  ? AppLocalizations.of(context)!.please_select_gender
                  : null,
              key: _genderFieldKey,
            ),
          ),
        ),
      ],
    );
  }
}
