class Installment {
  final String id;
  final String paymentId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InstallmentStatus status;
  final String? notes;

  Installment({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = InstallmentStatus.pending,
    this.notes,
  });

  bool get isPaid => status == InstallmentStatus.paid;
  
  bool get isOverdue => 
      status == InstallmentStatus.pending && 
      DateTime.now().isAfter(dueDate);

  Installment copyWith({
    String? id,
    String? paymentId,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    InstallmentStatus? status,
    String? notes,
  }) {
    return Installment(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status.toString(),
      'notes': notes,
    };
  }

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      paymentId: json['paymentId'] as String,
      amount: json['amount'] as double,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null 
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      status: InstallmentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => InstallmentStatus.pending,
      ),
      notes: json['notes'] as String?,
    );
  }
}

enum InstallmentStatus {
  pending,
  paid,
  overdue,
  cancelled
} 