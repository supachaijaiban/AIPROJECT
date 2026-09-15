import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('ocrReceipt')
external JSPromise<JSString> _ocrReceipt(JSString dataUrl);

/// Runs OCR on a receipt photo entirely in the browser via Tesseract.js
/// (see web/index.html) — free, no server call, no API key. Accuracy is
/// well below a vision LLM, especially on skewed/blurry phone photos and
/// Thai script, so callers must treat the result as a hint for a human
/// reviewer, never as a fact to act on automatically.
Future<String> extractReceiptText(Uint8List imageBytes, String mimeType) async {
  final dataUrl = 'data:$mimeType;base64,${base64Encode(imageBytes)}';
  final text = await _ocrReceipt(dataUrl.toJS).toDart;
  return text.toDart;
}
