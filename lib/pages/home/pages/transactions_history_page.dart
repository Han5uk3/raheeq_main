import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raheeq_main/common_widgets/custom_app_bar.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

class TransactionsHistoryPage extends StatefulWidget {
  final List<dynamic> transactions;

  const TransactionsHistoryPage({super.key, required this.transactions});

  @override
  State<TransactionsHistoryPage> createState() => _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends State<TransactionsHistoryPage> {
  String _selectedFilter = 'all';

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'all') return widget.transactions;

    final now = DateTime.now();
    return widget.transactions.where((tx) {
      DateTime date;
      try {
        date = DateTime.parse(tx['createdAt']).toLocal();
      } catch (_) {
        return true;
      }

      if (_selectedFilter == 'day') {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_selectedFilter == 'month') {
        return date.year == now.year && date.month == now.month;
      } else if (_selectedFilter == 'year') {
        return date.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: loc.all_transactions,
            subtitle: '',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text(
                  "${loc.filter_by}: ",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', loc.all),
                        const SizedBox(width: 8),
                        _buildFilterChip('day', loc.day),
                        const SizedBox(width: 8),
                        _buildFilterChip('month', loc.month),
                        const SizedBox(width: 8),
                        _buildFilterChip('year', loc.year),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      loc.no_transactions_found,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsetsDirectional.only(top: 4),
                          child: Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }
}
