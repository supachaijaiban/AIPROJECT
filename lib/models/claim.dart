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

  factory Claim.fromMap(Map<String, dynamic> map) {
    return Claim(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      requestedAmount: (map['requested_amount'] as num?)?.toDouble() ?? 0,
      approvedAmount: (map['approved_amount'] as num?)?.toDouble() ?? 0,
      receiptImageUrl: map['receipt_image_url'] as String? ?? '',
      status: claimStatusFromString(map['status'] as String? ?? 'pendingApprove'),
      aiNote: map['ai_note'] as String?,
      rejectReason: map['reject_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] == null ? null : DateTime.parse(map['reviewed_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'category': category,
      'requested_amount': requestedAmount,
      'approved_amount': approvedAmount,
      'receipt_image_url': receiptImageUrl,
      'status': status.name,
      'ai_note': aiNote,
      'reject_reason': rejectReason,
    };
  }
}
