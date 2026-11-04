import 'package:flutter_test/flutter_test.dart';
import 'package:mere_paise/core/utils/currency_formatter.dart';
import 'package:mere_paise/core/utils/date_utils.dart';
import 'package:mere_paise/features/models/category_item.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Formats paise to Indian currency string', () {
      expect(CurrencyFormatter.formatPaise(2000), '₹ 20');
      expect(CurrencyFormatter.formatPaise(24950), '₹ 249.50');
      expect(CurrencyFormatter.formatPaise(12500000), '₹ 1,25,000');
    });

    test('Parses keypad strings to paise integer', () {
      expect(CurrencyFormatter.parseToPaise('20'), 2000);
      expect(CurrencyFormatter.parseToPaise('249.50'), 24950);
      expect(CurrencyFormatter.parseToPaise('125000'), 12500000);
      expect(CurrencyFormatter.parseToPaise('0.5'), 50);
    });

    test('Signed paise formatting for Out and In', () {
      expect(CurrencyFormatter.formatSignedPaise(2000, isIncome: false), '− ₹ 20');
      expect(CurrencyFormatter.formatSignedPaise(500000, isIncome: true), '+ ₹ 5,000');
    });
  });

  group('DateUtils Tests', () {
    test('Calculates day, week, month, year keys correctly', () {
      final dt = DateTime(2026, 11, 4, 14, 30);
      expect(LedgerDateUtils.dayKey(dt), '2026-11-04');
      expect(LedgerDateUtils.monthKey(dt), '2026-11');
      expect(LedgerDateUtils.yearKey(dt), '2026');
      expect(LedgerDateUtils.weekKey(dt), contains('2026-W'));
    });
  });

  group('Default Categories Tests', () {
    test('Default expense categories are present', () {
      final expenses = CategoryItem.defaultExpenseCategories();
      expect(expenses.any((c) => c.name == 'Food & Dining'), isTrue);
      expect(expenses.any((c) => c.name == 'Groceries & Daily'), isTrue);
      expect(expenses.any((c) => c.name == 'Travel & Fuel'), isTrue);
    });

    test('Default income categories are present', () {
      final income = CategoryItem.defaultIncomeCategories();
      expect(income.any((c) => c.name == 'Salary'), isTrue);
      expect(income.any((c) => c.name == 'Freelance & Business'), isTrue);
    });
  });
}
