import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/models/checkout.dart';
import 'package:raheeq_main/pages/order/payment_status_page.dart';
import 'package:raheeq_main/services/network_monitor.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';

import 'package:flutter/services.dart';
import 'package:raheeq_main/utils/formatters.dart';

class IbanPaymentPage extends StatefulWidget {
  final bool isAr;
  final Map<String, dynamic> selectedBankAccount;
  final Checkout checkoutData;
  const IbanPaymentPage({
    super.key,
    required this.isAr,
    required this.selectedBankAccount,
    required this.checkoutData,
  });

  @override
  State<IbanPaymentPage> createState() => _IbanPaymentPageState();
}

class _IbanPaymentPageState extends State<IbanPaymentPage> {
  final ApiService _apiService = ApiService();
  // TextEditingController transactionController = TextEditingController();
  File? _receiptImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
    if (NetworkMonitor.instance.status.value == NetworkStatus.offline) {
      CustomSnackbar.show(
        isError: true,
        context: context,
        message: AppLocalizations.of(context)!.internet_error,
      );
      return;
    }
    final accountId =
        widget.selectedBankAccount['id']?.toString() ??
        widget.selectedBankAccount['_id']?.toString();

    if (_receiptImage == null) {
      CustomSnackbar.show(
        isError: true,
        context: context,
        message: AppLocalizations.of(
          context,
        )!.please_attach_the_transfer_receipt,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.createOrder(
        paymentMethod: 'IBAN',
        ibanBankAccountId: accountId,
        ibanReceipt: _receiptImage!.path,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

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
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      String? errorMessage;
      if (e is DioException &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMessage = e.response!.data['message'].toString();
      } else if (e is Exception) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.isNotEmpty) errorMessage = msg;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            status: PaymentStatus.failed,
            message: errorMessage,
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
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : _buildSubmitButton(),
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: AppLocalizations.of(context)!.iban_bank_transfer,
            subtitle: '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0.0, -1.0, 0.0),
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFF9F9F9),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (widget.selectedBankAccount['logo'] !=
                                          null) ...[
                                        Image.network(
                                          widget.selectedBankAccount['logo'],
                                          height: 40,
                                          width: 40,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.account_balance,
                                                    size: 40,
                                                  ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Text(
                                          (widget.isAr
                                                  ? widget
                                                        .selectedBankAccount['nameAr']
                                                        ?.toString()
                                                  : widget
                                                        .selectedBankAccount['name']
                                                        ?.toString()) ??
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
                                  const SizedBox(height: 16),
                                  _buildDetailRowWithCopy(
                                    AppLocalizations.of(
                                      context,
                                    )!.account_number,
                                    widget.selectedBankAccount['accountNumber']
                                            ?.toString() ??
                                        '',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRowWithCopy(
                                    'IBAN:',
                                    widget.selectedBankAccount['ibanNumber']
                                            ?.toString() ??
                                        '',
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!.iban_note,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Text(
                            //   AppLocalizations.of(
                            //     context,
                            //   )!.one_transaction_number,
                            //   style: const TextStyle(
                            //     fontSize: 18,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            // SizedBox(height: 8),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 16,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     border: Border.all(color: Colors.grey.shade300),
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: TextField(
                            //     cursorColor: AppColors.buttonBlueDark,

                            //     controller: transactionController,
                            //     decoration: InputDecoration(
                            //       border: InputBorder.none,
                            //       hintText: AppLocalizations.of(
                            //         context,
                            //       )!.enter_transaction_number,
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                              AppLocalizations.of(
                                context,
                              )!.two_attach_transfer_receipt,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                                Text(
                                  '\u202A${Formatters.formatPrice(widget.checkoutData.finalTotal, decimals: 2)} ${AppLocalizations.of(context)!.sar_currency}\u202C',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                              ],
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.tap_to_select_image,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBlueDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          disabledBackgroundColor: AppColors.buttonBlueDark.withValues(
            alpha: 0.8,
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: WaterLoadingIndicator(waveColor1: Colors.white),
              )
            : Text(
                AppLocalizations.of(context)!.confirm_submit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRowWithCopy(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.copy,
            size: 20,
            color: AppColors.buttonBlueDark,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
           
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
