import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_snackbar.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/pages/home/pages/transactions_history_page.dart';

class MyWalletPage extends StatefulWidget {
  const MyWalletPage({super.key});

  @override
  State<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage> {
  bool _isLoading = true;
  double _balance = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final response = await ApiService().getWallet();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _balance = (data['balance'] as num).toDouble();
          _transactions = data['transactions']['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CustomSnackbar.show(
            context: context,
            message: (response.data is Map && response.data['message'] != null)
                ? response.data['message']
                : AppLocalizations.of(context)!.failed_to_load_wallet,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = AppLocalizations.of(
          context,
        )!.error_msg(e.toString());
        if (e is DioException &&
            e.response?.data is Map &&
            e.response?.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: AppLocalizations.of(context)!.my_wallet,
            subtitle: '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              color: AppColors.buttonBlueDark,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(style: BorderStyle.none, width: 0),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : SingleChildScrollView(
                          key: const ValueKey('content'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWalletCard(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.transaction_history,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (_transactions.length > 10)
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TransactionsHistoryPage(
                                                    transactions: _transactions,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.show_more,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTransactionsList(),
                              ],
                            ),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  leading: const CircleAvatar(backgroundColor: Colors.white),
                  title: Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4),
                    child: Container(
                      width: 100,
                      height: 12,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Container(
                    width: 50,
                    height: 16,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.buttonBlueDark, AppColors.headerlightblue],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonBlueDark.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.current_balance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\u202A${AppLocalizations.of(context)!.sar_currency} ${_balance.toStringAsFixed(2)}\u202C',

            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_transactions_found,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final displayTransactions = _transactions.take(10).toList();

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTransactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tx = displayTransactions[index];
        final type = tx['type'] ?? 'UNKNOWN';
        final isCredit = type == 'CREDIT';
        final amount = tx['amount']?.toString() ?? '0';
        final note = tx['note'] ?? 'Transaction';

        DateTime date;
        try {
          date = DateTime.parse(tx['createdAt']);
        } catch (_) {
          date = DateTime.now();
        }

        final formattedDate = DateFormat(
          'MMM dd, yyyy • hh:mm a',
        ).format(date.toLocal());

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: isCredit
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            note,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(
              formattedDate,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          trailing: Text(
            "${isCredit ? '+' : '-'}$amount SAR",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
