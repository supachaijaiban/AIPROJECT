import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/claim.dart';
import 'claim_screening_service.dart';
import 'storage_service.dart';

class ClaimRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final StorageService _storage = StorageService();

  Stream<List<Claim>> streamClaimsForUser(String userId) {
    return _client
        .from('claims')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Claim.fromMap).toList());
  }

  /// Streams every claim visible to the caller (RLS scopes this to "own
  /// claims" for a user, "all claims" for an approver) and filters to
  /// pending ones in Dart. A server-side `.eq('status', ...)` filter looks
  /// right but silently stops delivering a row once its status changes to
  /// something outside the filter, so an approved/rejected claim would never
  /// be pushed to clients as "no longer pending" — it'd just stay stuck in
  /// the list until the next full reload.
  Stream<List<Claim>> streamPendingClaims() {
    return _client
        .from('claims')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map(Claim.fromMap)
            .where((claim) => claim.status == ClaimStatus.pendingApprove)
            .toList());
  }

  /// Runs the deterministic screening rules and writes the claim. The AI
  /// layer only ever picks reject-vs-forward here; approval always happens
  /// via the approve_claim RPC, called only from the Approver's screen.
  Future<void> submitClaim({
    required AppUser user,
    required String category,
    required double requestedAmount,
    required String fileName,
    required Uint8List receiptBytes,
  }) async {
    final receiptUrl = await _storage.uploadReceipt(
      userId: user.uid,
      fileName: fileName,
      bytes: receiptBytes,
    );

    final result = screenClaim(
      user: user,
      category: category,
      requestedAmount: requestedAmount,
    );

    final claim = Claim(
      id: '',
      userId: user.uid,
      userName: user.name,
      category: category,
      requestedAmount: requestedAmount,
      approvedAmount: result.decision == ScreeningDecision.forward ? result.forwardAmount : 0,
      receiptImageUrl: receiptUrl,
      status: result.decision == ScreeningDecision.reject
          ? ClaimStatus.rejected
          : ClaimStatus.pendingApprove,
      aiNote: result.note,
      rejectReason: result.decision == ScreeningDecision.reject ? result.note : null,
      createdAt: DateTime.now(),
    );

    await _client.from('claims').insert(claim.toInsertMap());
  }

  Future<void> approveClaim({required String claimId, required double approvedAmount}) {
    return _client.rpc('approve_claim', params: {
      'p_claim_id': claimId,
      'p_approved_amount': approvedAmount,
    });
  }

  Future<void> rejectClaim({required String claimId, required String reason}) {
    return _client.rpc('reject_claim', params: {
      'p_claim_id': claimId,
      'p_reason': reason,
    });
  }
}
