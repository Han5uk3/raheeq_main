import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

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

  String? _selectedGender;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
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
    _selectedGender = _currentUser?.gender ?? 'MALE';

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
            _selectedGender = _currentUser?.gender ?? 'MALE';
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

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final hasExistingEmail = _currentUser?.email != null && _currentUser!.email!.trim().isNotEmpty;
    final newEmail = _emailController.text.trim();
    final bool emailChanged = !hasExistingEmail && newEmail.isNotEmpty;

    final hasChanges =
        _firstNameController.text.trim() != (_currentUser?.firstName ?? '') ||
        _lastNameController.text.trim() != (_currentUser?.lastName ?? '') ||
        (_selectedGender?.toUpperCase() ?? 'MALE') !=
            (_currentUser?.gender?.toUpperCase() ?? 'MALE') ||
        _selectedAvatarPath != null ||
        emailChanged;

    if (!hasChanges) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService().updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: emailChanged ? newEmail : null,
        gender: _selectedGender?.toUpperCase() ?? 'MALE',
        profileImage: _selectedAvatarPath,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.profile_updated,
          );
          setState(() {
            _currentUser = AuthStorage.user;
            _isEditing = false;
            _selectedAvatarPath = null;
          });
        }
      } else {
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: response.data['message'] ?? "Failed to update profile",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(context)!.error_msg(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedAvatarPath = pickedFile.path;
        });
      }
    } catch (e, stackTrace) {
      log(
        'Error picking image: $e',
        name: 'Profile',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(
            context,
          )!.failed_to_pick_image(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _showAvatarBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Change Profile Photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAvatarOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(context)!.camera,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAvatar(ImageSource.camera);
                    },
                  ),
                  _buildAvatarOption(
                    icon: Icons.photo_library_outlined,
                    label: AppLocalizations.of(context)!.gallery,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAvatar(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.buttonBlueDark),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvatar(String mockPath) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService().updateProfile(profileImage: mockPath);

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: AppLocalizations.of(context)!.profile_pic_updated,
          );
          setState(() {
            _currentUser = AuthStorage.user;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: AppLocalizations.of(
            context,
          )!.failed_upload_simulation(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomAppBar(
                    hasBackgroundColor: true,
                    isStartAligned: true,
                    title: AppLocalizations.of(context)!.personal_information,
                    showBackButton: true,
                    onBackTap: () => Navigator.pop(context),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                _isEditing
                                    ? Symbols.save_sharp
                                    : Symbols.edit_square_sharp,
                                color: Colors.black,
                                size: 20,
                              ),
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      if (_isEditing) {
                                        _saveProfileChanges();
                                      } else {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      }
                                    },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    color: const Color(0x4D91E3FE),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
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
                        child: (_isLoading || _isSaving)
                            ? SizedBox(
                                key: const ValueKey('loader'),
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: const Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: WaterLoadingIndicator(size: 30),
                                  ),
                                ),
                              )
                            : Column(
                                key: const ValueKey('content'),
                                children: [
                                  // Upper blue header block with avatar and details
                                  Card(
                                    margin: EdgeInsets.all(24),
                                    color: Colors.white,
                                    child: Center(
                                      child: Column(
                                        children: [
                                          SizedBox(height: 50),
                                          GestureDetector(
                                            onTap: _isEditing
                                                ? _showAvatarBottomSheet
                                                : null,
                                            child: Stack(
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
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        blurRadius: 15,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 50,
                                                    backgroundColor:
                                                        const Color(0xFFF0F4F8),
                                                    backgroundImage:
                                                        _selectedAvatarPath !=
                                                            null
                                                        ? FileImage(
                                                                File(
                                                                  _selectedAvatarPath!,
                                                                ),
                                                              )
                                                              as ImageProvider
                                                        : (avatarUrl != null &&
                                                                  avatarUrl
                                                                      .isNotEmpty
                                                              ? CachedNetworkImageProvider(
                                                                  avatarUrl,
                                                                )
                                                              : null),
                                                    child:
                                                        _selectedAvatarPath ==
                                                                null &&
                                                            (avatarUrl ==
                                                                    null ||
                                                                avatarUrl
                                                                    .isEmpty)
                                                        ? const Icon(
                                                            Icons
                                                                .person_rounded,
                                                            size: 55,
                                                            color: Colors.grey,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                if (_isEditing)
                                                  PositionedDirectional(
                                                    bottom: 0,
                                                    end: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.amber[600],
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.camera_alt,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Profile Picture",
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
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      children: [
                                        // USER FORM SECTION
                                        Form(
                                          key: _formKey,
                                          child: Builder(
                                            builder: (context) {
                                              final hasExistingEmail = _currentUser?.email != null &&
                                                  _currentUser!.email!.trim().isNotEmpty;
                                              return Column(
                                                children: [
                                              _buildTextField(
                                                controller:
                                                    _firstNameController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.first_name,
                                                hint: "Enter your first name",
                                                enabled: _isEditing,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _lastNameController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.last_name,
                                                hint: "Enter your last name",
                                                enabled: _isEditing,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _emailController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.email_address,
                                                hint: "Enter your email",
                                                enabled: _isEditing && !hasExistingEmail,
                                                isOptional: true,
                                                isEmail: true,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildTextField(
                                                controller: _phoneController,
                                                label: AppLocalizations.of(
                                                  context,
                                                )!.phone_number,
                                                hint: "Enter your phone number",
                                                enabled: false,
                                              ),
                                              const SizedBox(height: 16),
                                              _buildGenderDropdown(),
                                              const SizedBox(height: 48),
                                              ],
                                              );
                                            }
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
                ],
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
          child: TextFormField(
            cursorColor: AppColors.buttonBlueDark,

            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.black87 : Colors.grey[600],
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isEditing ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.indicatorGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              borderRadius: BorderRadius.circular(15),
              dropdownColor: Colors.white,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              initialValue: _selectedGender,

              hint: Text(
                "Select Gender",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              items: ["MALE", "FEMALE", "OTHER"]
                  .map(
                    (label) => DropdownMenuItem(
                      value: label,
                      child: Text(
                        label[0] + label.substring(1).toLowerCase(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  : null,
              decoration: InputDecoration(border: InputBorder.none),
              validator: (value) =>
                  value == null ? 'Please select gender' : null,
            ),
          ),
        ),
      ],
    );
  }
}
