import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/claim.dart';
import 'claim_screening_service.dart';
import 'storage_service.dart';

class ClaimRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  Stream<List<Claim>> streamClaimsForUser(String userId) {
    return _db
        .collection('claims')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Claim.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Claim>> streamPendingClaims() {
    return _db
        .collection('claims')
        .where('status', isEqualTo: ClaimStatus.pendingApprove.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Claim.fromMap(d.id, d.data())).toList());
  }

  /// Runs the deterministic screening rules and writes the claim. The AI
  /// layer only ever picks reject-vs-forward here; approval always happens
  /// in [approveClaim] by a human Approver.
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

    final claimRef = _db.collection('claims').doc();
    await claimRef.set(Claim(
      id: claimRef.id,
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
    ).toMap());
  }

  /// Approves a claim and deducts the user's remaining allowance atomically,
  /// so two approvals racing on the same user can't both read a stale balance.
  Future<void> approveClaim({
    required String claimId,
    required String approverUid,
    required double approvedAmount,
  }) async {
    await _db.runTransaction((tx) async {
      final claimRef = _db.collection('claims').doc(claimId);
      final claimSnap = await tx.get(claimRef);
      if (!claimSnap.exists) throw Exception('Claim not found');
      final claim = Claim.fromMap(claimSnap.id, claimSnap.data()!);
      if (claim.status != ClaimStatus.pendingApprove) {
        throw Exception('Claim already reviewed');
      }

      final userRef = _db.collection('users').doc(claim.userId);
      final userSnap = await tx.get(userRef);
      final currentRemaining = (userSnap.data()?['allowanceRemaining'] as num?)?.toDouble() ?? 0;
      final newRemaining = (currentRemaining - approvedAmount).clamp(0, double.infinity);

      tx.update(userRef, {'allowanceRemaining': newRemaining});
      tx.update(claimRef, {
        'status': ClaimStatus.approved.name,
        'approvedAmount': approvedAmount,
        'reviewedBy': approverUid,
        'reviewedAt': Timestamp.now(),
      });
    });
  }

  Future<void> rejectClaim({
    required String claimId,
    required String approverUid,
    required String reason,
  }) async {
    await _db.collection('claims').doc(claimId).update({
      'status': ClaimStatus.rejected.name,
      'rejectReason': reason,
      'reviewedBy': approverUid,
      'reviewedAt': Timestamp.now(),
    });
  }
}
