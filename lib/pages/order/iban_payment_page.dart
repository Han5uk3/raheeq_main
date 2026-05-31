import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/pages/order/payment_status_page.dart';
import 'package:raheeq_main/utils/colors.dart';

class IbanPaymentPage extends StatefulWidget {
  final bool isAr;

  const IbanPaymentPage({super.key, required this.isAr});

  @override
  State<IbanPaymentPage> createState() => _IbanPaymentPageState();
}

class _IbanPaymentPageState extends State<IbanPaymentPage> {
  final ApiService _apiService = ApiService();
  TextEditingController transactionController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _bankAccounts = [];
  File? _receiptImage;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    try {
      final response = await _apiService.getBankAccounts();
      if (response.data['success'] == true) {
        setState(() {
          final List<dynamic> accounts = response.data['data'] ?? [];
          _bankAccounts = accounts
              .where((acc) => acc['isActive'] == true)
              .toList();
          _bankAccounts.sort((a, b) {
            final int orderA =
                int.tryParse(a['sortOrder']?.toString() ?? '0') ?? 0;
            final int orderB =
                int.tryParse(b['sortOrder']?.toString() ?? '0') ?? 0;
            return orderA.compareTo(orderB);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'فشل تحميل الحسابات البنكية'
                : 'Failed to load bank accounts',
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_receiptImage == null && transactionController.text == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'الرجاء إرفاق إيصال التحويل وإدخال رقم العملية'
                : 'Please attach the transfer receipt and enter the transaction number',
          ),
        ),
      );
      return;
    }
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'الرجاء إرفاق إيصال التحويل'
                : 'Please attach the transfer receipt',
          ),
        ),
      );
      return;
    }
    if (transactionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr
                ? 'الرجاء إدخال رقم العملية'
                : 'Please enter transaction number',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: WaterLoadingIndicator()),
    );

    try {
      final response = await _apiService.createOrder(
        paymentMethod: 'IBAN',
        ibanReceipt: _receiptImage!.path,
      );

      Navigator.pop(context); // close loader

      if (response.data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusPage(
              status: PaymentStatus.pendingApproval,
              isAr: widget.isAr,
            ),
          ),
        );
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      Navigator.pop(context); // close loader
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            status: PaymentStatus.failed,
            message: e.toString(),
            isAr: widget.isAr,
            onRetry: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isAr ? 'تحويل بنكي (IBAN)' : 'IBAN Bank Transfer'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: WaterLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isAr ? 'حساباتنا المصرفية' : 'Our Bank Accounts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_bankAccounts.isEmpty)
                    Text(
                      widget.isAr
                          ? 'لا توجد حسابات بنكية متاحة'
                          : 'No bank accounts available',
                    )
                  else
                    ..._bankAccounts.map((account) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF9F9F9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (account['logo'] != null) ...[
                                  Image.network(
                                    account['logo'],
                                    height: 40,
                                    width: 40,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.account_balance,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    (widget.isAr
                                            ? account['nameAr']?.toString()
                                            : account['name']?.toString()) ??
                                        '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              widget.isAr ? 'رقم الحساب:' : 'Account Number:',
                              account['accountNumber']?.toString() ?? '',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'IBAN:',
                              account['ibanNumber']?.toString() ?? '',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 32),
                  Text(
                    widget.isAr ? '1. رقم العملية:' : '1. Transaction Number :',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: transactionController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.isAr
                            ? 'أدخل رقم العملية'
                            : 'Enter transaction number',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isAr
                        ? '2. أرفق إيصال التحويل'
                        : '2. Attach Transfer Receipt',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: _receiptImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _receiptImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.isAr
                                      ? 'اضغط لاختيار صورة'
                                      : 'Tap to select image',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlueDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.isAr ? 'تأكيد وإرسال' : 'Confirm & Submit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
