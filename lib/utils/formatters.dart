import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(cleanText) / 100;
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text == '.') return newValue;
    
    // Remove all non-numeric characters except first dot
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    int dotCount = '.'.allMatches(cleanText).length;
    if (dotCount > 1) return oldValue;
    
    // Split into integer and decimal parts
    final parts = cleanText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Format integer part with thousands separators
    if (integerPart.isNotEmpty) {
      try {
        final formatter = NumberFormat('#,###');
        integerPart = formatter.format(int.parse(integerPart.replaceAll(',', '')));
      } catch (e) {
        return oldValue;
      }
    }

    String formatted = integerPart;
    if (decimalPart != null) {
      formatted += '.$decimalPart';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
