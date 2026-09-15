import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/claim.dart';
import '../../services/claim_repository.dart';

class ApproverDashboardPage extends StatelessWidget {
  const ApproverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการรออนุมัติ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => appState.authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Claim>>(
        stream: ClaimRepository().streamPendingClaims(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final claims = snapshot.data!;
          if (claims.isEmpty) return const Center(child: Text('ไม่มีรายการรออนุมัติ'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            itemBuilder: (context, i) {
              final claim = claims[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${claim.userName} — ${claim.category}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('ยอดที่ขอ: ${currency.format(claim.requestedAmount)}'),
                      Text('ยอดที่ AI แนะนำส่งต่อ: ${currency.format(claim.approvedAmount)}'),
                      if (claim.aiNote != null) Text(claim.aiNote!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(claim.receiptImageUrl, height: 180, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => _approve(context, claim.id, claim.approvedAmount),
                            child: const Text('อนุมัติ'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _rejectDialog(context, claim.id),
                            child: const Text('ปฏิเสธ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(BuildContext context, String claimId, double approvedAmount) async {
    try {
      await ClaimRepository().approveClaim(claimId: claimId, approvedAmount: approvedAmount);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อนุมัติไม่สำเร็จ: $e')));
      }
    }
  }

  Future<void> _rejectDialog(BuildContext context, String claimId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เหตุผลที่ปฏิเสธ'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await ClaimRepository().rejectClaim(claimId: claimId, reason: reason.trim());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ปฏิเสธไม่สำเร็จ: $e')));
      }
    }
  }
}
