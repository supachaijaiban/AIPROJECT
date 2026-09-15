import '../models/app_user.dart';

enum ScreeningDecision { forward, reject }

class ScreeningResult {
  final ScreeningDecision decision;
  final double forwardAmount;
  final String note;

  const ScreeningResult({
    required this.decision,
    required this.forwardAmount,
    required this.note,
  });
}

/// Deterministic rule checks only (allowance balance, category eligibility).
/// Receipt-content checks (payee name match, amount/category read off the
/// image) need a vision/OCR model and are not wired in yet — until that
/// exists, every claim that passes the rule checks below is still forwarded
/// to the Approver to eyeball the receipt itself, per the "ไม่แน่ใจ >> ส่งต่อ"
/// rule. The AI never auto-approves; it only decides reject-vs-forward.
ScreeningResult screenClaim({
  required AppUser user,
  required String category,
  required double requestedAmount,
}) {
  if (user.allowanceRemaining <= 0) {
    return const ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'วงเงินคงเหลือหมดแล้ว',
    );
  }

  if (!user.allowedCategories.contains(category)) {
    return const ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'ประเภทค่าใช้จ่ายนี้ไม่อยู่ในเงื่อนไขที่อนุญาตสำหรับผู้ใช้นี้',
    );
  }

  if (requestedAmount <= user.allowanceRemaining) {
    return ScreeningResult(
      decision: ScreeningDecision.forward,
      forwardAmount: requestedAmount,
      note: 'วงเงินเพียงพอ ส่งต่อให้ Approver พิจารณา',
    );
  }

  return ScreeningResult(
    decision: ScreeningDecision.forward,
    forwardAmount: user.allowanceRemaining,
    note: 'วงเงินไม่พอเต็มจำนวน ส่งต่อเท่ากับวงเงินคงเหลือ (${user.allowanceRemaining.toStringAsFixed(2)})',
  );
}
