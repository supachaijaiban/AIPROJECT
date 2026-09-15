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

/// Deterministic rules, in the order the original spec lists them: balance,
/// then receipt identity, then category, then amount-vs-balance. The AI
/// never approves — every non-reject outcome here still goes to a human
/// Approver, per "ไม่แน่ใจ >> ส่งต่อ".
///
/// The OCR identity/amount checks (via [receiptAnalysis]) are blunt by
/// explicit request: an unreadable photo or a name not found in the OCR
/// text both reject outright, even though many ordinary receipts have no
/// printed customer name at all and free OCR misreads Thai text often.
/// That false-reject risk was flagged and the request confirmed anyway —
/// don't "soften" this back to a note without being asked.
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

  if (receiptAnalysis != null && !receiptAnalysis.ocrReadable) {
    return const ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'อ่านข้อความจากใบเสร็จไม่ได้เลย กรุณาถ่ายรูปใหม่ให้ชัดเจนแล้วยื่นใหม่อีกครั้ง',
    );
  }

  if (receiptAnalysis != null && !receiptAnalysis.nameFound) {
    return ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'ไม่พบชื่อ "${user.name}" ในใบเสร็จ',
    );
  }

  if (!user.allowedCategories.contains(category)) {
    return const ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'ประเภทค่าใช้จ่ายนี้ไม่อยู่ในเงื่อนไขที่อนุญาตสำหรับผู้ใช้นี้',
    );
  }

  if (receiptAnalysis != null && receiptAnalysis.amountMismatch) {
    return ScreeningResult(
      decision: ScreeningDecision.reject,
      forwardAmount: 0,
      note: 'ยอดเงินในใบเสร็จ (${receiptAnalysis.extractedAmount!.toStringAsFixed(2)} บาท) '
          'ไม่ตรงกับยอดที่กรอก (${requestedAmount.toStringAsFixed(2)} บาท)',
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
    note: 'วงเงินไม่พอเต็มจำนวน ส่งต่อเท่ากับวงเงินคงเหลือ '
        '(${user.allowanceRemaining.toStringAsFixed(2)})',
  );
}
