import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/order/iban_payment_page.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';

class ChooseIbanAccountBottomSheet extends StatefulWidget {
  final bool isAr;

  const ChooseIbanAccountBottomSheet({super.key, required this.isAr});

  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required bool isAr,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => ChooseIbanAccountBottomSheet(isAr: isAr),
    );
  }

  @override
  State<ChooseIbanAccountBottomSheet> createState() =>
      _ChooseIbanAccountBottomSheetState();
}

class _ChooseIbanAccountBottomSheetState
    extends State<ChooseIbanAccountBottomSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bankAccounts = [];
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
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackbar.show(
        context: context,
        message:
            AppLocalizations.of(context)?.failed_to_load_bank_accounts ??
            'Failed to load bank accounts',
        isError: true,
      );
    }
  }

  void _toggleSlot(String id) {
    setState(() {
      if (_selectedBankAccountId == id) {
        _selectedBankAccountId = null; // deselect
      } else {
        _selectedBankAccountId = id;
      }
    });
  }

  bool get _isContinueEnabled => _selectedBankAccountId != null;

  void _navigateToIbanPaymentPage() {
    if (!_isContinueEnabled) return;

    final selectedAccount = _bankAccounts.firstWhere(
      (account) =>
          (account['id']?.toString() ?? account['_id']?.toString()) ==
          _selectedBankAccountId,
    );

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IbanPaymentPage(
          isAr: widget.isAr,
          selectedBankAccount: selectedAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'IBAN Accounts'; // You could localize these
    final subtitle = 'Select a bank for the transfer';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Container(
              width: 70,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal slot list
          SizedBox(
            height: 180,
            child: _isLoading
                ? _buildShimmerLoading()
                : _bankAccounts.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(
                            context,
                          )?.no_bank_accounts_available ??
                          'No bank accounts available',
                    ),
                  )
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: _bankAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _bankAccounts[index];
                      final id =
                          account['id']?.toString() ??
                          account['_id']?.toString();
                      final isSelected = _selectedBankAccountId == id;

                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 16.0 : 2.0,
                          right: index == _bankAccounts.length - 1 ? 16.0 : 2.0,
                        ),
                        child: _buildSlotCard(
                          account: account,
                          isSelected: isSelected,
                          onTap: () => _toggleSlot(id ?? ""),
                          isAr: widget.isAr,
                        ),
                      );
                    },
                  ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isContinueEnabled
                    ? _navigateToIbanPaymentPage
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isContinueEnabled
                      ? AppColors.buttonBlueDark
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  AppLocalizations.of(context)?.continue_btn ?? 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 16.0 : 2.0,
            right: index == 2 ? 16.0 : 2.0,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 125,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotCard({
    required dynamic account,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAr,
  }) {
    final name =
        (isAr ? account['nameAr']?.toString() : account['name']?.toString()) ??
        '';
    final logo = account['logo'];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 125,
        height: 160,
        child: Card(
          color: Colors.white,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bank image
              if (logo != null)
                Image.network(
                  logo,
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance,
                    size: 60,
                    color: AppColors.buttonBlueDark,
                  ),
                )
              else
                const Icon(
                  Icons.account_balance,
                  size: 60,
                  color: AppColors.buttonBlueDark,
                ),
              const SizedBox(height: 12),
              // Bank name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
