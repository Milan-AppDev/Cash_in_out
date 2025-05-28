class Transaction {
  final String id;
  final String paymentId;
  final String? installmentId;
  final double amount;
  final DateTime transactionDate;
  final TransactionType type;
  final String? reference;
  final String? notes;

  Transaction({
    required this.id,
    required this.paymentId,
    this.installmentId,
    required this.amount,
    required this.transactionDate,
    required this.type,
    this.reference,
    this.notes,
  });

  Transaction copyWith({
    String? id,
    String? paymentId,
    String? installmentId,
    double? amount,
    DateTime? transactionDate,
    TransactionType? type,
    String? reference,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      installmentId: installmentId ?? this.installmentId,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'installmentId': installmentId,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'type': type.toString(),
      'reference': reference,
      'notes': notes,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      paymentId: json['paymentId'] as String,
      installmentId: json['installmentId'] as String?,
      amount: json['amount'] as double,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.payment,
      ),
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

enum TransactionType {
  payment,
  refund,
  adjustment,
  cancellation
} 