import '../models/expense_model.dart';

class ExpenseExtractor {
  static final RegExp _amountRegex = RegExp(r'\$?\b(\d+(?:\.\d{1,2})?)\b');
  
  static final Map<String, List<String>> _categoryKeywords = {
    'Food': ['food', 'burger', 'pizza', 'coffee', 'grocery', 'restaurant', 'lunch', 'dinner', 'breakfast'],
    'Travel': ['travel', 'flight', 'uber', 'taxi', 'bus', 'train', 'gas', 'fare'],
    'Shopping': ['shopping', 'shirt', 'shoes', 'clothes', 'mall'],
    'Bills': ['bill', 'electricity', 'rent', 'water', 'internet', 'phone'],
  };

  static Expense extract(String text) {
    String lowerText = text.toLowerCase();
    
    // Extract Amount
    double amount = 0.0;
    final amountMatch = _amountRegex.firstMatch(lowerText);
    String cleanedDesc = text;

    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
      cleanedDesc = cleanedDesc.replaceFirst(amountMatch.group(0)!, '');
    }
    
    // Extract Category
    String category = 'Other';
    for (var entry in _categoryKeywords.entries) {
      final kwMatch = entry.value.where((keyword) => lowerText.contains(keyword)).toList();
      if (kwMatch.isNotEmpty) {
        category = entry.key;
        for (var kw in kwMatch) {
          cleanedDesc = cleanedDesc.replaceAll(RegExp(kw, caseSensitive: false), '');
        }
        break;
      }
    }
    
    // Extract Date/Time
    DateTime date = DateTime.now();
    
    if (lowerText.contains('yesterday') || lowerText.contains('last night')) {
      date = date.subtract(const Duration(days: 1));
      cleanedDesc = cleanedDesc.replaceAll(RegExp(r'yesterday|last night', caseSensitive: false), '');
    } else if (lowerText.contains('tomorrow')) {
      date = date.add(const Duration(days: 1));
      cleanedDesc = cleanedDesc.replaceAll(RegExp(r'tomorrow', caseSensitive: false), '');
    }
    
    // Match specific times (e.g., "at 5pm", "at 5:30", "at 18:00")
    // Expanded regex handles dots in p.m. or a.m. and spaces
    final timeRegex = RegExp(r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(lowerText);
    if (timeMatch != null) {
      int hour = int.tryParse(timeMatch.group(1) ?? '12') ?? 12;
      final minuteStr = timeMatch.group(2);
      int minute = minuteStr != null ? int.parse(minuteStr) : 0;
      
      String amPm = (timeMatch.group(3) ?? '').replaceAll('.', '').toLowerCase();
      
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
      
      date = DateTime(date.year, date.month, date.day, hour, minute);
      cleanedDesc = cleanedDesc.replaceFirst(RegExp(timeMatch.group(0)!, caseSensitive: false), '');
    }
    
    // Final clean up of description
    cleanedDesc = cleanedDesc.replaceAll(RegExp(r'\b(?:on|for|at|spent|paid|bought)\b', caseSensitive: false), '');
    cleanedDesc = cleanedDesc.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (cleanedDesc.isEmpty) {
      cleanedDesc = "Voice Expense";
    }
    
    return Expense(
      amount: amount,
      category: category,
      date: date,
      description: cleanedDesc,
    );
  }
}
