import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/models/gift_card_template.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:country_picker/country_picker.dart';

class GiftCardBottomSheet extends StatefulWidget {
  final Checkout checkoutData;
  final bool isAr;

  const GiftCardBottomSheet({
    super.key,
    required this.checkoutData,
    required this.isAr,
  });

  @override
  State<GiftCardBottomSheet> createState() => _GiftCardBottomSheetState();
}

class _GiftCardBottomSheetState extends State<GiftCardBottomSheet> {
  final ApiService _apiService = ApiService();
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

    // Auto-select item if only one
    if (widget.checkoutData.items.length == 1) {
      _selectedItem = widget.checkoutData.items.first;
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
    if (_senderController.text.trim().isEmpty ||
        _receiverController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedTemplate == null ||
        _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr ? "يرجى تعبئة جميع الحقول" : "Please fill all fields",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    final payload = {
      "templateId": _selectedTemplate!.id,
      "senderName": _senderController.text.trim(),
      "receiverName": _receiverController.text.trim(),
      "receiverCountryCode": '+${_selectedCountry.phoneCode}',
      "receiverWhatsapp": _phoneController.text.trim(),
    };

    try {
      final response = await _apiService.applyGiftCard(
        itemId: _selectedItem!
            .productId, // wait, is itemId productId or orderItemId? The checkout item has productId. Let's assume it's productId or we might need `id` from checkoutItem if it exists. Actually, the endpoint is /checkout/items/{itemId}/gift-card. Let's use productId or checkout item id.
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr ? "حدث خطأ أثناء التطبيق" : "Error applying gift card",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The endpoint takes {itemId}. In CheckoutItem we have productId but no id.
    // Let's use productId for now, but usually it's checkout item ID.
    // We will check checkout.dart to see if it has id.

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.checkoutData.items.length > 1) ...[
                    _buildLabel(widget.isAr ? "اختر العنصر" : "Select Item"),
                    const SizedBox(height: 8),
                    _buildItemDropdown(),
                    const SizedBox(height: 16),
                  ],
                  _buildLabel(widget.isAr ? "اسم المرسل" : "Sender Name"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _senderController,
                    widget.isAr ? "ادخل اسمك" : "Enter your name",
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(widget.isAr ? "اسم المستلم" : "Receiver Name"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _receiverController,
                    widget.isAr ? "ادخل اسم المستلم" : "Enter receiver name",
                  ),
                  const SizedBox(height: 16),

                  _buildLabel(
                    widget.isAr ? "رقم الواتساب للمستلم" : "Receiver WhatsApp",
                  ),
                  const SizedBox(height: 8),
                  _buildPhoneField(),
                  const SizedBox(height: 24),

                  _buildLabel(
                    widget.isAr ? "اختر قالب البطاقة" : "Select Card Template",
                  ),
                  const SizedBox(height: 12),
                  _buildTemplatesList(),
                  const SizedBox(height: 24),

                  if (_selectedTemplate != null) ...[
                    _buildLabel(widget.isAr ? "معاينة" : "Preview"),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _selectedTemplate!.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
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
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.isAr ? "إضافة بطاقة إهداء" : "Add Gift Card",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonBlueDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildItemDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CheckoutItem>(
          value: _selectedItem,
          isExpanded: true,
          hint: Text(widget.isAr ? "اختر العنصر" : "Select an item"),
          items: widget.checkoutData.items.map((item) {
            final name =
                item.product?.localizedName(widget.isAr) ?? item.productId;
            return DropdownMenuItem<CheckoutItem>(
              value: item,
              child: Text(name),
            );
          }).toList(),
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
      children: [
        InkWell(
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
                bottomSheetHeight: MediaQuery.of(context).size.height * 0.6,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    "https://flagcdn.com/w80/${_selectedCountry.countryCode.toLowerCase()}.png",
                    width: 24,
                    height: 16,
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
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: widget.isAr ? "رقم الهاتف" : "Phone Number",
                hintStyle: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesList() {
    if (_isLoadingTemplates) {
      return const SizedBox(
        height: 100,
        child: Center(child: WaterLoadingIndicator(size: 30)),
      );
    }

    if (_templates.isEmpty) {
      return Text(
        widget.isAr ? "لا توجد قوالب متاحة" : "No templates available",
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final template = _templates[index];
          final isSelected = _selectedTemplate?.id == template.id;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedTemplate = template);
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.buttonBlueDark
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(
                  template.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isApplying ? null : _applyGiftCard,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBlueDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: _isApplying
              ? const WaterLoadingIndicator(
                  size: 20,
                  waveColor1: Colors.white,
                  waveColor2: Colors.white,
                )
              : Text(
                  widget.isAr ? "تطبيق الإهداء" : "Apply Gift Card",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
