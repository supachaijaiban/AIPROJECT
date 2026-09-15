class ReceiptAnalysis {
  /// False when OCR returned essentially no text (bad photo, unsupported
  /// angle, etc.) — too little to check anything against.
  final bool ocrReadable;
  final bool nameFound;
  final double? extractedAmount;
  final bool amountMismatch;
  final String note;

  const ReceiptAnalysis({
    required this.ocrReadable,
    required this.nameFound,
    required this.extractedAmount,
    required this.amountMismatch,
    required this.note,
  });
}

final _keywordAmountPattern = RegExp(r'(รวม|ยอดรวม|total|สุทธิ|net)', caseSensitive: false);
final _numberPattern = RegExp(r'[0-9][0-9,]*\.?[0-9]{0,2}');

/// Rule-based read of free OCR text (see receipt_ocr_service.dart — no
/// vision LLM involved, Tesseract.js only). Deliberately blunt by request:
/// unreadable OCR or a name not found in the text are both treated as
/// reject signals by the caller, even though ordinary receipts often have
/// no printed customer name at all — that tradeoff was made explicitly
/// after flagging the false-reject risk, not something to "fix" silently.
ReceiptAnalysis analyzeReceiptText(
  String rawText, {
  required double userEnteredAmount,
  required String userName,
}) {
  final ocrReadable = rawText.trim().length >= 5;
  final amount = ocrReadable ? _findTotalAmount(rawText) : null;
  final nameFound = ocrReadable && _containsName(rawText, userName);

  final amountMismatch = amount != null &&
      (amount - userEnteredAmount).abs() > 1 &&
      (amount - userEnteredAmount).abs() / userEnteredAmount > 0.02;

  final notes = <String>[];
  if (!ocrReadable) {
    notes.add('OCR อ่านข้อความจากใบเสร็จไม่ได้เลย');
  } else {
    notes.add(amount == null
        ? 'OCR อ่านยอดเงินจากใบเสร็จไม่ได้'
        : (amountMismatch
            ? 'OCR อ่านยอดได้ ${amount.toStringAsFixed(2)} บาท ต่างจากที่กรอก (${userEnteredAmount.toStringAsFixed(2)} บาท)'
            : 'OCR อ่านยอดได้ ${amount.toStringAsFixed(2)} บาท ตรงกับที่กรอก'));
    notes.add(nameFound ? 'พบชื่อ "$userName" ในใบเสร็จ' : 'ไม่พบชื่อ "$userName" ในใบเสร็จ');
  }

  return ReceiptAnalysis(
    ocrReadable: ocrReadable,
    nameFound: nameFound,
    extractedAmount: amount,
    amountMismatch: amountMismatch,
    note: notes.join(' / '),
  );
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
