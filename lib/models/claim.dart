import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus { pendingApprove, approved, rejected }

ClaimStatus claimStatusFromString(String value) {
  return ClaimStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ClaimStatus.pendingApprove,
  );
}

class Claim {
  final String id;
  final String userId;
  final String userName;
  final String category;
  final double requestedAmount;
  final double approvedAmount;
  final String receiptImageUrl;
  final ClaimStatus status;
  final String? aiNote;
  final String? rejectReason;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const Claim({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.requestedAmount,
    required this.approvedAmount,
    required this.receiptImageUrl,
    required this.status,
    this.aiNote,
    this.rejectReason,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Claim.fromMap(String id, Map<String, dynamic> map) {
    return Claim(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      requestedAmount: (map['requestedAmount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (map['approvedAmount'] as num?)?.toDouble() ?? 0,
      receiptImageUrl: map['receiptImageUrl'] as String? ?? '',
      status: claimStatusFromString(map['status'] as String? ?? 'pendingApprove'),
      aiNote: map['aiNote'] as String?,
      rejectReason: map['rejectReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'category': category,
      'requestedAmount': requestedAmount,
      'approvedAmount': approvedAmount,
      'receiptImageUrl': receiptImageUrl,
      'status': status.name,
      'aiNote': aiNote,
      'rejectReason': rejectReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
    };
  }
}
