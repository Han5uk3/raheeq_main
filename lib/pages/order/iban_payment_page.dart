import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';
import 'package:raheeq_main/pages/order/payment_status_page.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';

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
  String? _selectedBankAccountId;

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
          if (_bankAccounts.isNotEmpty) {
            _selectedBankAccountId =
                _bankAccounts.first['id']?.toString() ??
                _bankAccounts.first['_id']?.toString();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.failed_to_load_bank_accounts,
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
    if (_selectedBankAccountId == null) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.please_select_bank_account,
      );
      return;
    }
    if (_receiptImage == null && transactionController.text == '') {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.please_attach_the_transfer_receipt_and_enter_the_transaction_number,
      );
      return;
    }
    if (_receiptImage == null) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.please_attach_the_transfer_receipt,
      );
      return;
    }
    if (transactionController.text.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: AppLocalizations.of(context)!.please_enter_transaction_number,
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
        ibanBankAccountId: _selectedBankAccountId,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading ? null : _buildSubmitButton(),
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
                child: _isLoading
                    ? const Center(child: WaterLoadingIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24.0,
                                24.0,
                                24.0,
                                100.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.our_bank_accounts,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.please_select_designated_bank_account,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_bankAccounts.isEmpty)
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.no_bank_accounts_available,
                                    )
                                  else
                                    ..._bankAccounts.map((account) {
                                      final accountId =
                                          account['id']?.toString() ??
                                          account['_id']?.toString();
                                      final isSelected =
                                          _selectedBankAccountId == accountId;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedBankAccountId = accountId;
                                          });
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsetsDirectional.only(
                                                bottom: 12,
                                              ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.buttonBlueDark
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: isSelected
                                                ? AppColors.buttonBlueDark
                                                      .withOpacity(0.05)
                                                : const Color(0xFFF9F9F9),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (account['logo'] !=
                                                      null) ...[
                                                    Image.network(
                                                      account['logo'],
                                                      height: 40,
                                                      width: 40,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => const Icon(
                                                            Icons
                                                                .account_balance,
                                                            size: 40,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      (widget.isAr
                                                              ? account['nameAr']
                                                                    ?.toString()
                                                              : account['name']
                                                                    ?.toString()) ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: AppColors
                                                            .buttonBlueDark,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              _buildDetailRow(
                                                AppLocalizations.of(
                                                  context,
                                                )!.account_number,
                                                account['accountNumber']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(
                                                'IBAN:',
                                                account['ibanNumber']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  const SizedBox(height: 32),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.one_transaction_number,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      cursorColor: AppColors.buttonBlueDark,

                                      controller: transactionController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.enter_transaction_number,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.two_attach_transfer_receipt,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
        onPressed: _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBlueDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.confirm_submit,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
