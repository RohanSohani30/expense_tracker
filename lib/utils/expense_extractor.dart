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
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
    }
    
    // Extract Category
    String category = 'Other';
    for (var entry in _categoryKeywords.entries) {
      if (entry.value.any((keyword) => lowerText.contains(keyword))) {
        category = entry.key;
        break;
      }
    }
    
    // Extract Date/Time
    DateTime date = DateTime.now();
    if (lowerText.contains('yesterday') || lowerText.contains('last night')) {
      date = date.subtract(const Duration(days: 1));
    } else if (lowerText.contains('tomorrow')) {
      date = date.add(const Duration(days: 1));
    }
    
    // Match specific times (e.g., "at 5pm", "at 5:30", "at 18:00")
    final timeRegex = RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?');
    final timeMatch = timeRegex.firstMatch(lowerText);
    if (timeMatch != null) {
      int hour = int.tryParse(timeMatch.group(1) ?? '12') ?? 12;
      final minuteStr = timeMatch.group(2);
      int minute = minuteStr != null ? int.parse(minuteStr) : 0;
      final amPm = timeMatch.group(3);
      
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
      
      date = DateTime(date.year, date.month, date.day, hour, minute);
    }
    
    // Description is the full text
    String description = text.trim();
    if (description.isEmpty) {
      description = "Unknown expense";
    }
    
    return Expense(
      amount: amount,
      category: category,
      date: date,
      description: description,
    );
  }
}
