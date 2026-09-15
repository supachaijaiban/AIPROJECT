class ReceiptAnalysis {
  final double? extractedAmount;
  final bool nameFound;
  final String note;

  const ReceiptAnalysis({
    required this.extractedAmount,
    required this.nameFound,
    required this.note,
  });
}

final _keywordAmountPattern = RegExp(r'(รวม|ยอดรวม|total|สุทธิ|net)', caseSensitive: false);
final _numberPattern = RegExp(r'[0-9][0-9,]*\.?[0-9]{0,2}');

/// Rule-based read of free OCR text — a hint for the human Approver, never
/// grounds for auto-rejecting a claim. See receipt_ocr_service.dart for why:
/// no vision LLM is involved, so both the amount and the name check below
/// can easily be wrong on a real photographed receipt.
ReceiptAnalysis analyzeReceiptText(
  String rawText, {
  required double userEnteredAmount,
  required String userName,
}) {
  final amount = _findTotalAmount(rawText);
  final nameFound = _containsName(rawText, userName);

  final notes = <String>[];
  if (amount == null) {
    notes.add('OCR อ่านยอดเงินจากใบเสร็จไม่ได้');
  } else {
    final diff = (amount - userEnteredAmount).abs();
    final withinTolerance = diff <= 1 || diff / userEnteredAmount <= 0.02;
    notes.add(withinTolerance
        ? 'OCR อ่านยอดได้ ${amount.toStringAsFixed(2)} บาท ตรงกับที่กรอก'
        : 'OCR อ่านยอดได้ ${amount.toStringAsFixed(2)} บาท ต่างจากที่กรอก (${userEnteredAmount.toStringAsFixed(2)} บาท) — โปรดตรวจสอบ');
  }

  notes.add(nameFound
      ? 'พบชื่อ "$userName" ในข้อความที่อ่านได้จากใบเสร็จ'
      : 'ไม่พบชื่อ "$userName" ในข้อความที่อ่านได้ (ใบเสร็จร้านค้าทั่วไปมักไม่มีชื่อลูกค้าอยู่แล้ว ไม่ได้แปลว่าใบเสร็จผิดคน)');

  return ReceiptAnalysis(extractedAmount: amount, nameFound: nameFound, note: notes.join(' / '));
}

double? _findTotalAmount(String text) {
  for (final line in text.split('\n')) {
    if (!_keywordAmountPattern.hasMatch(line)) continue;
    final matches = _numberPattern.allMatches(line).toList();
    if (matches.isEmpty) continue;
    final value = double.tryParse(matches.last.group(0)!.replaceAll(',', ''));
    if (value != null && value > 0) return value;
  }

  double? largest;
  for (final match in _numberPattern.allMatches(text)) {
    final value = double.tryParse(match.group(0)!.replaceAll(',', ''));
    if (value != null && value > 0 && (largest == null || value > largest)) {
      largest = value;
    }
  }
  return largest;
}

bool _containsName(String text, String userName) {
  final parts = userName.split(RegExp(r'\s+')).where((p) => p.length >= 2);
  return parts.any(text.contains);
}
