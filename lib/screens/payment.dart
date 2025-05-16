//import 'package:flutter/foundation.dart';
import 'package:cash_in_out/models/installment.dart'; // Adjust the import according to your project structure

class Payment {
  final String id;
  final String clientId; // This will link to the client module later
  final double totalAmount;
  final double paidAmount;
  final DateTime createdDate;
  final DateTime dueDate;
  final String description;
  final PaymentStatus status;
  final List<Installment> installments;

  Payment({
    required this.id,
    required this.clientId,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.createdDate,
    required this.dueDate,
    this.description = '',
    this.status = PaymentStatus.pending,
    this.installments = const [],
  });

  double get remainingAmount => totalAmount - paidAmount;

  bool get isCompleted => paidAmount >= totalAmount;

  Payment copyWith({
    String? id,
    String? clientId,
    double? totalAmount,
    double? paidAmount,
    DateTime? createdDate,
    DateTime? dueDate,
    String? description,
    PaymentStatus? status,
    List<Installment>? installments,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      status: status ?? this.status,
      installments: installments ?? this.installments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'createdDate': createdDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'status': status.toString(),
      'installments': installments.map((i) => i.toJson()).toList(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      totalAmount: json['totalAmount'] as double,
      paidAmount: json['paidAmount'] as double,
      createdDate: DateTime.parse(json['createdDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      description: json['description'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      installments:
          (json['installments'] as List)
              .map((i) => Installment.fromJson(i as Map<String, dynamic>))
              .toList(),
    );
  }
}

enum PaymentStatus { pending, partiallyPaid, completed, overdue, cancelled }
