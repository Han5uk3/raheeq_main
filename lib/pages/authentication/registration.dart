import 'package:flutter/material.dart';
import 'package:raheeq_main/common_widgets/language_switch.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/pages/home/home_screen.dart';
import 'package:raheeq_main/pages/authentication/login.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';

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
        title: const Text(
          "Complete Profile",
          style: TextStyle(
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
      body: SingleChildScrollView(
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
                            hint: "Enter your first name",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _lastNameController,
                            label: AppLocalizations.of(context)!.last_name,
                            hint: "Enter your last name",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label:
                                "${AppLocalizations.of(context)!.email_address} (${Localizations.localeOf(context).languageCode == 'ar' ? 'اختياري' : 'Optional'})",
                            hint:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? "أدخل البريد الإلكتروني (اختياري)"
                                : "Enter your email (optional)",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isEmail: true,
                            isOptional: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: AppLocalizations.of(context)!.phone_number,
                            hint: "Enter phone number",
                            icon: Icons.phone_outlined,
                            enabled: false, // Pre-filled and locked
                            isLtr: true,
                          ),

                          const SizedBox(height: 16),
                          _buildGenderDropdown(),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    final response = await ApiService().register(
                                      countryCode: widget.countryCode,
                                      phoneNumber: widget.phoneNumber
                                          .replaceAll(widget.countryCode, '')
                                          .trim(), // Ensure pure phone number
                                      email: _emailController.text.trim(),
                                      firstName: _firstNameController.text
                                          .trim(),
                                      lastName: _lastNameController.text.trim(),
                                      gender:
                                          _selectedGender?.toUpperCase() ??
                                          'MALE',
                                      deviceType: 'ANDROID',
                                      registrationToken:
                                          widget.registrationToken,
                                    );

                                    if (!context.mounted) return;

                                    if ((response.statusCode == 200 ||
                                            response.statusCode == 201) &&
                                        response.data['success'] == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Registration Successful!',
                                          ),
                                        ),
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            response.data['message'] ??
                                                'Registration failed',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.error_msg(e.toString()),
                                        ),
                                      ),
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
                              child: const Text(
                                "Register",
                                style: TextStyle(
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
    bool isLtr = false,
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
            textAlign: isLtr ? TextAlign.end : TextAlign.start,
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            textDirection: isLtr ? TextDirection.ltr : null,
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
                return 'This field is required';
              }
              if (isEmail) {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(trimmedValue)) {
                  return 'Please enter a valid email address';
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
        const Text(
          "Gender",
          style: TextStyle(
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
                "Select Gender",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              items: ["Male", "Female", "Other"]
                  .map(
                    (label) => DropdownMenuItem(
                      value: label,
                      child: Text(label, style: const TextStyle(fontSize: 14)),
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
              validator: (value) =>
                  value == null ? 'Please select gender' : null,
              key: _genderFieldKey,
            ),
          ),
        ),
      ],
    );
  }
}
