import 'dart:developer';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:raheeq_main/api/new.dart';
import 'package:raheeq_main/utils/rtl_helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/models/gift_card_template.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:country_picker/country_picker.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class GiftCardPage extends StatefulWidget {
  final Checkout checkoutData;
  final bool isAr;

  const GiftCardPage({
    super.key,
    required this.checkoutData,
    required this.isAr,
  });

  @override
  State<GiftCardPage> createState() => _GiftCardPageState();
}

class _GiftCardPageState extends State<GiftCardPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<GiftCardTemplate> _templates = [];
  bool _isLoadingTemplates = true;
  bool _isApplying = false;

  GiftCardTemplate? _selectedTemplate;
  CheckoutItem? _selectedItem;

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
    _fetchTemplates();

    // Auto-select first item
    final availableItems = widget.checkoutData.items
        .where((item) => item.giftCard == null)
        .toList();
    if (availableItems.isNotEmpty) {
      _selectedItem = availableItems.first;
    }
  }

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchTemplates() async {
    try {
      final response = await _apiService.getGiftCardTemplates();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _templates = data.map((e) => GiftCardTemplate.fromJson(e)).toList();
          if (_templates.isNotEmpty) {
            _selectedTemplate = _templates.first;
          }
          _isLoadingTemplates = false;
        });
      } else {
        setState(() => _isLoadingTemplates = false);
      }
    } catch (e) {
      log('Error fetching templates: $e');
      setState(() => _isLoadingTemplates = false);
    }
  }

  Future<void> _applyGiftCard() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return;
    }

    if (_selectedTemplate == null || _selectedItem == null) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.please_select_template,
        isError: true,
      );
      return;
    }

    setState(() => _isApplying = true);

    String apiPhoneText = _phoneController.text.trim();
    if (_selectedCountry.phoneCode == '966' && apiPhoneText.startsWith('0')) {
      apiPhoneText = apiPhoneText.substring(1);
    }

    final payload = {
      "templateId": _selectedTemplate!.id,
      "senderName": _senderController.text.trim(),
      "receiverName": _receiverController.text.trim(),
      "receiverCountryCode": '+${_selectedCountry.phoneCode}',
      "receiverWhatsapp": apiPhoneText,
    };

    try {
      final response = await _apiService.applyGiftCard(
        itemId: _selectedItem!.id!,
        giftCardData: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedCheckout = Checkout.fromJson(response.data['data']);
        Navigator.pop(context, updatedCheckout);
      } else {
        throw Exception("Failed to apply");
      }
    } catch (e) {
      log('Error applying gift card: $e');
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.error_applying_gift_card,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isApplying,
      child: Scaffold(
        body: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CustomAppBar(
                hasBackgroundColor: true,
                isStartAligned: true,
                title: AppLocalizations.of(context)!.add_gift_card,
                subtitle: '',
                showBackButton: true,
                onBackTap: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.buttonBlueDark,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 120,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 24,
                            bottom: 8,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildLabel(
                            AppLocalizations.of(context)!.select_card_template,
                          ),
                        ),

                        _buildTemplatesList(),

                        if (_isLoadingTemplates) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 16,
                              left: 16,
                              right: 16,
                            ),
                            child: AspectRatio(
                              aspectRatio: 406 / 324,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else if (_selectedTemplate != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 16,
                              left: 16,
                              right: 16,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Material(
                                elevation: 4,
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: AspectRatio(
                                  aspectRatio: 406 / 324,
                                  child: GestureDetector(
                                    onTap: () => _showImageDialog(
                                      context,
                                      _selectedTemplate!.image,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: _selectedTemplate!.image,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.white,
                                            ),
                                          ),
                                      fit: BoxFit.contain,
                                      errorWidget:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (widget.checkoutData.items
                                .where((item) => item.giftCard == null)
                                .length >
                            1) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 0,
                              bottom: 8,
                              left: 16,
                              right: 16,
                            ),
                            child: _buildLabel(
                              AppLocalizations.of(context)!.select_sub_order,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              top: 0,
                              bottom: 16,
                              left: 16,
                              right: 16,
                            ),
                            child: _buildItemDropdown(),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 8,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildLabel(
                            AppLocalizations.of(context)!.sender_name_title,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildTextField(
                            _senderController,
                            AppLocalizations.of(context)!.enter_sender_name,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 8,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildLabel(
                            AppLocalizations.of(context)!.receiver_name_title,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildTextField(
                            _receiverController,
                            AppLocalizations.of(context)!.enter_receiver_name,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 8,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildLabel(
                            AppLocalizations.of(context)!.receiver_whatsapp,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildPhoneField(),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: _buildApplyButton(),
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      cursorColor: AppColors.buttonBlueDark,
      style: const TextStyle(color: AppColors.black, fontSize: 12),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context)!.field_is_required;
        }
        return null;
      },
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: AppColors.black.withValues(alpha: 0.8),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintText: hint,
      ),
    );
  }

  Widget _buildItemDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _selectedItem != null
            ? Border.all(color: AppColors.buttonBlueDark)
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CheckoutItem>(
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          value: _selectedItem,
          isExpanded: true,
          hint: Text(AppLocalizations.of(context)!.select_sub_order),
          items: widget.checkoutData.items
              .where((item) => item.giftCard == null)
              .map((item) {
                final productName =
                    item.product?.localizedName(widget.isAr) ?? item.productId;

                String? locationName;
                if (item.location != null && item.location is Map) {
                  locationName = widget.isAr
                      ? item.location['nameAr']
                      : item.location['name'];
                } else if (item.city != null && item.city is Map) {
                  locationName = widget.isAr
                      ? item.city['nameAr']
                      : item.city['name'];
                }

                String extraInfo =
                    locationName ??
                    item.category?.localizedLabel(widget.isAr) ??
                    '';
                String displayName = extraInfo.isNotEmpty
                    ? "$productName - $extraInfo"
                    : productName;

                return DropdownMenuItem<CheckoutItem>(
                  value: item,
                  child: Text(displayName),
                );
              })
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedItem = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.buttonBlueDark,
            ),
          ),
          child: Builder(
            builder: (context) => InkWell(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  onSelect: (Country country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },

                  countryListTheme: CountryListThemeData(
                    textStyle: const TextStyle(color: AppColors.black),
                    searchTextStyle: const TextStyle(color: AppColors.black),
                    bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    inputDecoration: InputDecoration(
                      prefixIconColor: AppColors.buttonBlueDark,
                      hintStyle: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.8),
                      ),
                      hintText: AppLocalizations.of(context)!.search,
                      prefixIcon: const Icon(Icons.search),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.buttonBlueDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.buttonBlueDark),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: AppColors.buttonBlueDark),
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.buttonBlueDark),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        "https://flagcdn.com/w80/${_selectedCountry.countryCode.toLowerCase()}.png",
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.flag, size: 20),
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
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.black),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            cursorColor: AppColors.buttonBlueDark,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: AppColors.black, fontSize: 14),
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.phone_number_required;
              }
              if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                return AppLocalizations.of(context)!.invalid_phone_number;
              }
              if (_selectedCountry.phoneCode == '966') {
                if (value.startsWith('0') && value.length != 10) {
                  return AppLocalizations.of(context)!.enter_valid_number_gc;
                } else if (value.startsWith('5') && value.length != 9) {
                  return AppLocalizations.of(context)!.enter_valid_number_gc;
                } else if (!value.startsWith('0') && !value.startsWith('5')) {
                  return AppLocalizations.of(context)!.enter_valid_number_gc;
                }
              } else {
                try {
                  final phone = PhoneNumber.parse(
                    '+${_selectedCountry.phoneCode}${value.trim()}',
                  );
                  if (!phone.isValid(type: PhoneNumberType.mobile) &&
                      !phone.isValid()) {
                    return AppLocalizations.of(context)!.enter_valid_number_gc;
                  }
                } catch (e) {
                  return AppLocalizations.of(context)!.invalid_phone_format;
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintStyle: TextStyle(
                color: AppColors.black.withValues(alpha: 0.8),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: AppLocalizations.of(context)!.phone_number_hint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesList() {
    if (_isLoadingTemplates) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            5,
            (index) => Padding(
              padding: EdgeInsetsGeometry.directional(start: 16, end: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 80,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_templates.isEmpty) {
      return Text(AppLocalizations.of(context)!.no_templates_available);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsetsGeometry.directional(start: 16, end: 16),
        child: Row(
          children: _templates.map((template) {
            final isSelected = _selectedTemplate?.id == template.id;
            final name = widget.isAr ? template.nameAr : template.name;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                elevation: 2,
                label: Text(name),
                selected: isSelected,
                selectedColor: AppColors.buttonBlueDark,
                backgroundColor: isSelected
                    ? AppColors.buttonBlueDark
                    : AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.buttonBlueDark),
                ),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTemplate = template);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton(
      onPressed: _isApplying ? null : _applyGiftCard,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonBlueDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: _isApplying
          ? const WaterLoadingIndicator(size: 20, waveColor1: Colors.white)
          : Text(
              AppLocalizations.of(context)!.save_gift_card_info,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black87),
            ),
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 40,
              start: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  highlightColor: Colors.transparent,
                  icon: Icon(backArrowIcon(context)),
                  color: Colors.black87,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
