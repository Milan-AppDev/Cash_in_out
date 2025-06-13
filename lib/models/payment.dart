//import 'package:flutter/foundation.dart';
import 'package:cash_in_out/models/installment.dart';
import 'package:intl/intl.dart';

class Payment {
  String id;
  final String clientId;
  final String clientName;
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
    this.clientName = '',
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
    String? clientName,
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
      clientName: clientName ?? this.clientName,
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
      'name': clientName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'createdDate': DateFormat('yyyy-MM-dd').format(createdDate),
      'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
      'description': description,
      'status':
          status
              .toString()
              .split('.')
              .last, // Use 'pending' instead of 'PaymentStatus.pending'
      'installments': installments.map((i) => i.toJson()).toList(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      clientId: json['clientId'].toString(),
      clientName: json['name'] ?? '', // Parse from JSON
      totalAmount: double.parse(json['totalAmount'].toString()),
      paidAmount: double.parse(json['paidAmount'].toString()),
      createdDate: DateTime.parse(json['createdDate']),
      dueDate: DateTime.parse(json['dueDate']),
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      installments:
          json['installments'] != null
              ? (json['installments'] as List)
                  .map((i) => Installment.fromJson(i))
                  .toList()
              : [],
    );
  }

  // Helper method for parsing status
  static PaymentStatus _parseStatus(dynamic statusValue) {
    if (statusValue == null) return PaymentStatus.pending;

    // Handle both full enum string and just the name
    final statusString = statusValue.toString().toLowerCase();
    if (statusString.contains('pending')) return PaymentStatus.pending;
    if (statusString.contains('partiallypaid'))
      return PaymentStatus.partiallyPaid;
    if (statusString.contains('completed')) return PaymentStatus.completed;
    if (statusString.contains('overdue')) return PaymentStatus.overdue;
    if (statusString.contains('cancelled')) return PaymentStatus.cancelled;

    return PaymentStatus.pending; // Default
  }
}

enum PaymentStatus { pending, partiallyPaid, completed, overdue, cancelled }
