import 'package:intl/intl.dart';

/// Formatter for money stored strictly as integer paise.
/// 1 Rupee = 100 Paise. No floating point representation.
/// Formatting conforms to the Indian numbering system (lakhs, crores).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static final NumberFormat _inrFormatterCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 0,
  );

  /// Converts paise to formatted Indian rupee string:
  /// e.g. 24950 -> "₹ 249.50", 12500000 -> "₹ 1,25,000"
  static String formatPaise(int paise, {bool forceDecimals = false, bool includeSymbol = true}) {
    final double rupees = paise / 100.0;
    final bool hasPaise = (paise % 100) != 0;

    String formatted;
    if (forceDecimals || hasPaise) {
      formatted = _inrFormatterWithDecimals.format(rupees);
    } else {
      formatted = _inrFormatterCompact.format(rupees);
    }

    if (!includeSymbol) {
      formatted = formatted.replaceFirst('₹ ', '').replaceFirst('₹', '').trim();
    }
    return formatted;
  }

  /// Formats with explicit sign:
  /// e.g. Out: "− ₹ 249.50", In: "+ ₹ 5,000"
  static String formatSignedPaise(int paise, {required bool isIncome, bool forceDecimals = false}) {
    final String absFormatted = formatPaise(paise.abs(), forceDecimals: forceDecimals);
    final String sign = isIncome ? '+ ' : '− ';
    return '$sign$absFormatted';
  }

  /// Parses keypad decimal string (e.g. "250.75" or "100") directly to integer paise
  static int parseToPaise(String text) {
    final clean = text.replaceAll('₹', '').replaceAll(',', '').trim();
    if (clean.isEmpty) return 0;

    if (!clean.contains('.')) {
      final whole = int.tryParse(clean) ?? 0;
      return whole * 100;
    }

    final parts = clean.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    } else if (decimalPart.length == 1) {
      decimalPart = '${decimalPart}0';
    } else if (decimalPart.isEmpty) {
      decimalPart = '00';
    }

    final fractional = int.tryParse(decimalPart) ?? 0;
    return (whole * 100) + fractional;
  }

  /// Converts paise back to displayable input string: e.g. 24950 -> "249.50"
  static String paiseToInputString(int paise) {
    final rupees = paise ~/ 100;
    final remainingPaise = paise % 100;
    if (remainingPaise == 0) {
      return '$rupees';
    }
    return '$rupees.${remainingPaise.toString().padLeft(2, '0')}';
  }
}

