import 'package:flutter/material.dart';

import '../models/claim.dart';

class StatusBadge extends StatelessWidget {
  final ClaimStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ClaimStatus.pendingApprove => ('Pending Approve', Colors.orange),
      ClaimStatus.approved => ('Approved', Colors.green),
      ClaimStatus.rejected => ('Rejected', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
