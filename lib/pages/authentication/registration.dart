import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
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
  final bool isSocialLogin;
  final String? email;
  final String? firstName;
  final String? lastName;

  const Registration({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.registrationToken,
    this.isSocialLogin = false,
    this.email,
    this.firstName,
    this.lastName,
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
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  bool _isRegistering = false;
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

  @override
  void initState() {
    super.initState();
    if (widget.isSocialLogin) {
      if (widget.firstName != null)
       {
        {
          _firstNameController.text = widget.firstName!;
        }
      }
      if (widget.lastName != null) _lastNameController.text = widget.lastName!;
      if (widget.email != null) _emailController.text = widget.email!;
    } else {
      _phoneController.text = '${widget.countryCode}${widget.phoneNumber}';
    }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.buttonBlueDark,
        appBar: AppBar(
          backgroundColor: AppColors.buttonBlueDark,
          shape: Border.all(width: 0, color: AppColors.buttonBlueDark),
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
                        top: 16,
                        start: 16,
                        end: 16,
                        bottom: 16,
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
                              child: InkWell(
                                onTap: _pickImage,
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
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: const Color(
                                          0xFFF0F4F8,
                                        ),
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                                  as ImageProvider
                                            : null,
                                        child: _profileImage == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Color.fromRGBO(
                                                  158,
                                                  158,
                                                  158,
                                                  1,
                                                ),
                                              )
                                            : null,
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
                            ),
                              const SizedBox(height: 12),
                            _buildTextField(
                              controller: _firstNameController,
                              label: AppLocalizations.of(context)!.first_name,
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_first_name,
                   
                            ),
                              const SizedBox(height: 12),
                            _buildTextField(
                              controller: _lastNameController,
                              label: AppLocalizations.of(context)!.last_name,
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_last_name,
                         
                            ),
                              const SizedBox(height: 12),
                            _buildTextField(
                              controller: _emailController,
                              label: widget.isSocialLogin
                                  ? AppLocalizations.of(context)!.email_address
                                  : "${AppLocalizations.of(context)!.email_address} (${AppLocalizations.of(context)!.optional})",
                              hint: AppLocalizations.of(
                                context,
                              )!.enter_email_optional_hint,
                      
                              keyboardType: TextInputType.emailAddress,
                              isEmail: true,
                              isOptional: !widget.isSocialLogin,
                              enabled: !widget.isSocialLogin,
                            ),
                              const SizedBox(height: 12),
                            widget.isSocialLogin
                                  ? _buildSocialPhoneInput(_phoneController)
                                : _buildTextField(
                                    controller: _phoneController,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.phone_number,
                                    hint: AppLocalizations.of(
                                      context,
                                    )!.enter_phone_number_hint,
                            
                                    enabled: false, // Pre-filled and locked
                                    isRtl:
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'ar',
                                  ),

                              const SizedBox(height: 12),
                            _buildGenderDropdown(),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRegistering
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          if (widget.isSocialLogin) {
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
                                                  '+${_selectedCountry.phoneCode}$phoneText',
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
                                          }

                                          setState(() => _isRegistering = true);
                                          try {
                                            String apiPhoneText =
                                                _phoneController.text.trim();
                                            if (widget.isSocialLogin &&
                                                _selectedCountry.phoneCode ==
                                                    '966' &&
                                                apiPhoneText.startsWith('0')) {
                                              apiPhoneText = apiPhoneText
                                                  .substring(1);
                                            }

                                            final response = await ApiService()
                                                .register(
                                                  countryCode:
                                                      widget.isSocialLogin
                                                      ? '+${_selectedCountry.phoneCode}'
                                                      : widget.countryCode,
                                                  phoneNumber:
                                                      widget.isSocialLogin
                                                      ? apiPhoneText
                                                      : widget.phoneNumber
                                                            .replaceAll(
                                                              widget
                                                                  .countryCode,
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
                                                        '',
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
                                              if (_profileImage != null) {
                                                try {
                                                  await ApiService()
                                                      .updateProfile(
                                                        profileImage:
                                                            _profileImage!.path,
                                                      );
                                                } catch (e) {
                                                  // Silent error on avatar upload failure
                                                }
                                              }
                                              if (!mounted) return;
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
                                          waveColor1: Colors.white,
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
      )
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  
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
        TextFormField(
          key: fieldKey,
          cursorColor: AppColors.buttonBlueDark,
          textAlign: isRtl ? TextAlign.end : TextAlign.start,
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled == false ? AppColors.grey : AppColors.black,
            fontSize: 14,
          ),
          textDirection: isRtl ? TextDirection.ltr : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: enabled == false
                  ? AppColors.grey
                  : AppColors.black.withValues(alpha: 0.8),
              fontSize: 14,
            ),
       
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.buttonBlueDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.buttonBlueDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.buttonBlueDark,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
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
        if (hasError && fieldKey?.currentState?.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            fieldKey!.currentState!.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderDropdown() {
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
        FormField<String>(
          key: _genderFieldKey,
          initialValue: _selectedGender,
          validator: (value) => value == null
              ? AppLocalizations.of(context)!.please_select_gender
              : null,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: state.hasError
                          ? Colors.red
                          : AppColors.indicatorGrey,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: state.value,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: state.hasError
                            ? Colors.red
                            : AppColors.buttonBlueDark,
                      ),
                      hint: Text(
                        AppLocalizations.of(context)!.select_gender,
                        style: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                        state.didChange(value);
                        state.validate();
                      },
                    ),
                  ),
                ),
                if (state.hasError && state.errorText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialPhoneInput(TextEditingController controller) {
    final fieldKey = _fieldKeys[controller];
    final hasError = fieldKey?.currentState?.hasError == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.phone_number,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.buttonBlueDark),
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
                        favorite: ["SA", "AE", "KW", "BH", "QA", "OM", "SD"],
                        context: context,
                        showPhoneCode: true,
                        onSelect: (Country country) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },
                        countryListTheme: CountryListThemeData(
                          bottomSheetHeight:
                              MediaQuery.of(context).size.height * 0.7,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          inputDecoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.search,
                            prefixIcon: const Icon(Icons.search),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: AppColors.buttonBlueDark,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: AppColors.buttonBlueDark,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
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
              Container(height: 24, width: 1, color: Colors.grey[300]),
              const SizedBox(width: 12),
              Expanded(
                child: FormField<String>(
                  key: fieldKey,
                  initialValue: _phoneController.text,
                  validator: (value) {
                    final trimmedValue = _phoneController.text.trim();
                    if (trimmedValue.isEmpty) {
                      return AppLocalizations.of(context)!.field_required;
                    }
                    return null;
                  },
                  builder: (FormFieldState<String> state) {
                    return TextField(
                      cursorColor: AppColors.buttonBlueDark,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          int maxLength = 15;
                          if (_selectedCountry.phoneCode == '966') {
                            if (newValue.text.startsWith('0')) {
                              maxLength = 10;
                            } else if (newValue.text.startsWith('5')) {
                              maxLength = 9;
                            } else {
                              maxLength = 10;
                            }
                          }
                          if (newValue.text.length > maxLength) {
                            if (oldValue.text.length < maxLength) {
                              return TextEditingValue(
                                text: newValue.text.substring(0, maxLength),
                                selection: TextSelection.collapsed(
                                  offset: newValue.selection.end > maxLength
                                      ? maxLength
                                      : newValue.selection.end,
                                ),
                              );
                            }
                            return oldValue;
                          }
                          return newValue;
                        }),
                      ],
                      onChanged: (value) {
                        state.didChange(value);
                        state.validate();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enter_phone,
                        hintStyle: TextStyle(
                          color: AppColors.black.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (hasError && fieldKey?.currentState?.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            fieldKey!.currentState!.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
