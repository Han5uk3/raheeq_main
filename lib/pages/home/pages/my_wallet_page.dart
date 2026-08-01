import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/models/wallet_model.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';

class MyWalletPage extends StatefulWidget {
  const MyWalletPage({super.key});

  @override
  State<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  double _balance = 0.0;
  String? _errorMessage;
  List<WalletTransaction> _transactions = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreTransactions();
    }
  }

  Future<void> _fetchWalletData() async {
    try {
      final response = await ApiService().getWallet(page: 1, limit: _pageSize);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final walletData = WalletData.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        log(
          'Parsed wallet: balance=${walletData.balance}, '
          'transactions=${walletData.transactions.length}, '
          'page=${walletData.page}, hasMore=${walletData.hasMore}',
          name: 'WalletAPI',
        );
        setState(() {
          _balance = walletData.balance;
          _transactions = walletData.transactions;
          _currentPage = walletData.page;
          _hasMore = walletData.hasMore;
          _isLoading = false;
        });
      } else {
        log(
          'Wallet fetch not applied: statusCode=${response.statusCode}, '
          'success=${response.data is Map ? response.data['success'] : response.data}',
          name: 'WalletAPI',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      log(
        'Error parsing wallet response: $e',
        name: 'WalletAPI',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        if (e.toString().contains('connection error')) {
          _errorMessage = AppLocalizations.of(context)!.internet_error;
        } else {
          _errorMessage = e.toString();
        }
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final response = await ApiService().getWallet(
        page: _currentPage + 1,
        limit: _pageSize,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final walletData = WalletData.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        setState(() {
          _transactions = [..._transactions, ...walletData.transactions];
          _currentPage = walletData.page;
          _hasMore = walletData.hasMore;
        });
      }
    } catch (e, stackTrace) {
      log(
        'Error loading more transactions: $e',
        name: 'WalletAPI',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
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
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWalletCard(),
                                const SizedBox(height: 24),
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
                                const SizedBox(height: 16),
                                _buildTransactionsList(),
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
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

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransactionCard(_transactions[index], isAr);
      },
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx, bool isAr) {
    final isCredit = tx.isCredit;
    final amount = tx.amount.toString();
    final note = tx.localizedNote(isAr);
    final date = tx.createdAt ?? DateTime.now();
    final accentColor = isCredit ? Colors.green : Colors.red;

    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(date.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.buttonBlueDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}\u202A${AppLocalizations.of(context)!.sar_currency} $amount\u202C',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
