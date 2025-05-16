import 'package:flutter/material.dart';
import 'installment.dart';

class InstallmentsListScreen extends StatefulWidget {
  const InstallmentsListScreen({super.key});

  @override
  State<InstallmentsListScreen> createState() => _InstallmentsListScreenState();
}

class _InstallmentsListScreenState extends State<InstallmentsListScreen> {
  List<Installment> installments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installments'),
      ),
      body: installments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No installments yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: installments.length,
              itemBuilder: (context, index) {
                final installment = installments[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Installment #${installment.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Amount: ₹${installment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due Date: ${installment.dueDate.toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(installment.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            installment.status.toString().split('.').last,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (installment.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${installment.notes}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        // TODO: Navigate to installment details
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add installment screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.pending:
        return Colors.orange;
      case InstallmentStatus.paid:
        return Colors.green;
      case InstallmentStatus.overdue:
        return Colors.red;
      case InstallmentStatus.cancelled:
        return Colors.grey;
    }
  }
} 