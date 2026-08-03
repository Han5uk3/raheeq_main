import 'package:flutter/material.dart';
import 'dart:io';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isLoading = false;

  String? _selectedAvatarPath;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = AuthStorage.user;
    _firstNameController = TextEditingController(
      text: _currentUser?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: _currentUser?.lastName ?? '',
    );
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
    _phoneController = TextEditingController(
      text: _currentUser != null
          ? '${_currentUser!.countryCode} ${_currentUser!.phoneNumber}'
          : '',
    );

    // Refresh user profile silently on load to match production APIs
    _refreshProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService().getProfile();
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _currentUser = AuthStorage.user;
            _firstNameController.text = _currentUser?.firstName ?? '';
            _lastNameController.text = _currentUser?.lastName ?? '';
            _emailController.text = _currentUser?.email ?? '';
            _phoneController.text = _currentUser != null
                ? '${_currentUser!.countryCode} ${_currentUser!.phoneNumber}'
                : '';
          });
        }
      }
    } catch (e) {
      // Fail silently or show subtle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.no_session)),
      );
    }

    final avatarUrl = _currentUser?.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: AppLocalizations.of(context)!.personal_information,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    child: (_isLoading)
                        ? _buildShimmerLoading()
                        : Column(
                            key: const ValueKey('content'),
                            children: [
                              // Upper blue header block with avatar and details
                              Card(
                                margin: EdgeInsets.all(16),
                                color: Colors.white,
                                child: Center(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 50),
                                      Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 4,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 15,
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 50,
                                              backgroundColor: const Color(
                                                0xFFF0F4F8,
                                              ),
                                              backgroundImage:
                                                  _selectedAvatarPath != null
                                                  ? FileImage(
                                                          File(
                                                            _selectedAvatarPath!,
                                                          ),
                                                        )
                                                        as ImageProvider
                                                  : (avatarUrl != null &&
                                                            avatarUrl.isNotEmpty
                                                        ? CachedNetworkImageProvider(
                                                            avatarUrl,
                                                          )
                                                        : null),
                                              child:
                                                  _selectedAvatarPath == null &&
                                                      (avatarUrl == null ||
                                                          avatarUrl.isEmpty)
                                                  ? const Icon(
                                                      Icons.person_rounded,
                                                      size: 55,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.profile_picture,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 50),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Username display
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  children: [
                                    // USER FORM SECTION
                                    Form(
                                      key: _formKey,
                                      child: Builder(
                                        builder: (context) {
                                          // final hasExistingEmail =
                                          //     _currentUser?.email != null &&
                                          //     _currentUser!.email
                                          //         .trim()
                                          //         .isNotEmpty;
                                          return Column(
                                            children: [
                                              _buildTextField(
                                                controller:
                                                    _firstNameController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.first_name,
                                                hint: AppLocalizations.of(
                                                  context,
                                                )!.enter_first_name,
                                                enabled: false,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _lastNameController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.last_name,
                                                hint: AppLocalizations.of(
                                                  context,
                                                )!.enter_last_name,
                                                enabled: false,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _emailController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.email_address,
                                                hint: AppLocalizations.of(
                                                  context,
                                                )!.enter_email_optional_hint,
                                                enabled: false,
                                                isOptional: true,
                                                isEmail: true,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _phoneController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.phone_number,
                                                hint: AppLocalizations.of(
                                                  context,
                                                )!.enter_phone_number_hint,
                                                enabled: false,
                                              ),
                                              // const SizedBox(height: 16),
                                              // _buildGenderDropdown(),
                                              const SizedBox(height: 48),
                                            ],
                                          );
                                        },
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
    bool isOptional = false,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.indicatorGrey),
          ),
          child: controller.text.isEmpty
              ? TextFormField(
                  controller: TextEditingController(text: "Email not provided"),
                  enabled: false,
                  style: const TextStyle(color: AppColors.grey, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )
              : TextFormField(
                  cursorColor: AppColors.buttonBlueDark,
                  controller: controller,
                  enabled: enabled,
                  style: const TextStyle(color: AppColors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.buttonBlueDark,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
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

 

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(24),
            color: Colors.white,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const CircleAvatar(radius: 50, backgroundColor: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 16, color: Colors.white),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 100, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
