/// Parses a value that may arrive as a JSON number or as a numeric string
/// (money fields from the API are serialized as strings to preserve precision).
num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String type;
  final num amount;
  final num? balanceBefore;
  final num? balanceAfter;
  final String? reference;
  final String note;
  final String? noteAr;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    this.reference,
    required this.note,
    this.noteAr,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      amount: _parseNum(json['amount']) ?? 0,
      balanceBefore: _parseNum(json['balanceBefore']),
      balanceAfter: _parseNum(json['balanceAfter']),
      reference: json['reference'] as String?,
      note: json['note'] as String? ?? 'Transaction',
      noteAr: json['noteAr'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  bool get isCredit => type == 'CREDIT';

  /// Returns the Arabic note when [isAr], falling back to [note] if [noteAr] is null or empty.
  String localizedNote(bool isAr) {
    if (isAr && noteAr != null && noteAr!.trim().isNotEmpty) {
      return noteAr!;
    }
    return note;
  }
}

class WalletData {
  final double balance;
  final List<WalletTransaction> transactions;
  final int page;
  final int totalPages;

  const WalletData({
    required this.balance,
    required this.transactions,
    this.page = 1,
    this.totalPages = 1,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final transactionsJson = json['transactions'] as Map<String, dynamic>?;
    final items = (transactionsJson?['items'] as List<dynamic>?) ?? const [];
    final meta = transactionsJson?['meta'] as Map<String, dynamic>?;
    return WalletData(
      balance: _parseNum(json['balance'])?.toDouble() ?? 0.0,
      transactions: items
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (meta?['page'] as num?)?.toInt() ?? 1,
      totalPages: (meta?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  bool get hasMore => page < totalPages;
}
