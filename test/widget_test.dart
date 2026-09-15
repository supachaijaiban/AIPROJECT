import 'package:flutter_test/flutter_test.dart';

import 'package:welfare_claim/models/app_user.dart';
import 'package:welfare_claim/services/claim_screening_service.dart';
import 'package:welfare_claim/services/receipt_analysis_service.dart';

AppUser _user({double remaining = 1000, List<String> categories = const ['medical']}) {
  return AppUser(
    uid: 'u1',
    name: 'Test User',
    email: 't@example.com',
    department: 'IT',
    role: UserRole.user,
    allowanceTotal: 5000,
    allowanceRemaining: remaining,
    allowedCategories: categories,
  );
}

void main() {
  test('rejects when allowance is fully used', () {
    final result = screenClaim(user: _user(remaining: 0), category: 'medical', requestedAmount: 100);
    expect(result.decision, ScreeningDecision.reject);
  });

  test('rejects when category is not allowed', () {
    final result = screenClaim(user: _user(), category: 'travel', requestedAmount: 100);
    expect(result.decision, ScreeningDecision.reject);
  });

  test('forwards full amount when allowance covers it', () {
    final result = screenClaim(user: _user(remaining: 1000), category: 'medical', requestedAmount: 400);
    expect(result.decision, ScreeningDecision.forward);
    expect(result.forwardAmount, 400);
  });

  test('forwards capped at remaining allowance when request exceeds it', () {
    final result = screenClaim(user: _user(remaining: 300), category: 'medical', requestedAmount: 1000);
    expect(result.decision, ScreeningDecision.forward);
    expect(result.forwardAmount, 300);
  });

  test('receipt analysis flags an amount that does not match what was typed', () {
    final analysis = analyzeReceiptText(
      'ร้านค้าทดสอบ\nรวมเงิน 500.00\nขอบคุณ',
      userEnteredAmount: 250,
      userName: 'Test User',
    );
    expect(analysis.extractedAmount, 500);
    expect(analysis.note, contains('ต่างจากที่กรอก'));
  });

  test('receipt analysis accepts an amount within tolerance of what was typed', () {
    final analysis = analyzeReceiptText(
      'ยอดรวม 199.50 บาท',
      userEnteredAmount: 199.50,
      userName: 'Test User',
    );
    expect(analysis.extractedAmount, 199.50);
    expect(analysis.note, contains('ตรงกับที่กรอก'));
  });

  test('receipt analysis reports whether the user name appears in the OCR text', () {
    final found = analyzeReceiptText('ใบเสร็จของ Test User', userEnteredAmount: 100, userName: 'Test User');
    expect(found.nameFound, true);

    final notFound = analyzeReceiptText('ร้านสะดวกซื้อ', userEnteredAmount: 100, userName: 'Test User');
    expect(notFound.nameFound, false);
  });
}
