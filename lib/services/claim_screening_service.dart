import '../models/app_user.dart';
import 'receipt_analysis_service.dart';

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

/// Deterministic rule checks (allowance balance, category eligibility) plus
/// an optional OCR read of the receipt, appended to the note as context for
/// the Approver — never as grounds to reject on its own. OCR here is free,
/// on-device Tesseract, not a vision model (see receipt_ocr_service.dart),
/// so it's too unreliable to decide anything by itself; every claim that
/// passes the rule checks below still goes to the Approver either way, per
/// the "ไม่แน่ใจ >> ส่งต่อ" rule. The AI never auto-approves.
ScreeningResult screenClaim({
  required AppUser user,
  required String category,
  required double requestedAmount,
  ReceiptAnalysis? receiptAnalysis,
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

  final suffix = receiptAnalysis == null ? '' : ' | ${receiptAnalysis.note}';

  if (requestedAmount <= user.allowanceRemaining) {
    return ScreeningResult(
      decision: ScreeningDecision.forward,
      forwardAmount: requestedAmount,
      note: 'วงเงินเพียงพอ ส่งต่อให้ Approver พิจารณา$suffix',
    );
  }

  return ScreeningResult(
    decision: ScreeningDecision.forward,
    forwardAmount: user.allowanceRemaining,
    note: 'วงเงินไม่พอเต็มจำนวน ส่งต่อเท่ากับวงเงินคงเหลือ '
        '(${user.allowanceRemaining.toStringAsFixed(2)})$suffix',
  );
}
