import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/claim.dart';
import '../../services/claim_repository.dart';
import '../../shared/status_badge.dart';
import 'upload_receipt_page.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: Text('สวัสดี ${user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => appState.authService.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UploadReceiptPage()),
        ),
        icon: const Icon(Icons.upload_file),
        label: const Text('ยื่นขอเบิก'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('วงเงินทั้งหมด: ${currency.format(user.allowanceTotal)}'),
                  const SizedBox(height: 4),
                  Text('วงเงินคงเหลือ: ${currency.format(user.allowanceRemaining)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('ประเภทที่เบิกได้: ${user.allowedCategories.join(", ")}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('รายการที่ยื่นขอเบิก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          StreamBuilder<List<Claim>>(
            stream: ClaimRepository().streamClaimsForUser(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final claims = snapshot.data!;
              if (claims.isEmpty) return const Text('ยังไม่มีรายการ');
              return Column(
                children: claims.map((c) {
                  return Card(
                    child: ListTile(
                      title: Text('${c.category} — ${currency.format(c.requestedAmount)}'),
                      subtitle: Text(c.aiNote ?? c.rejectReason ?? ''),
                      trailing: StatusBadge(status: c.status),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
