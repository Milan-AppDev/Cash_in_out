class Payment {
  final int? id;
  final int clientId;
  final double amount;
  final DateTime timestamp;
  final String tag;
  final String note;
  final String status;
  final int? installmentId; // ✅ NEW

  Payment({
    this.id,
    required this.clientId,
    required this.amount,
    required this.timestamp,
    required this.tag,
    required this.note,
    required this.status,
    this.installmentId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: int.tryParse(json['id'].toString()),
      clientId: int.parse(json['client_id'].toString()),
      amount: double.parse(json['amount'].toString()),
      timestamp: DateTime.parse(json['timestamp']),
      tag: json['tag'],
      note: json['note'],
      status: json['status'],
      installmentId:
          json['installment_id'] != null
              ? int.tryParse(json['installment_id'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'tag': tag,
    'note': note,
    'status': status,
    'installment_id': installmentId,
  };
}
