import 'package:flutter_test/flutter_test.dart';
import 'package:voice_expense/models/expense_model.dart';
import 'package:voice_expense/utils/expense_extractor.dart';

void main() {
  group('ExpenseExtractor Tests', () {
    test('Extracts amount correctly', () {
      Expense e1 = ExpenseExtractor.extract("I spent 50 dollars on food.");
      expect(e1.amount, 50.0);

      Expense e2 = ExpenseExtractor.extract("Paid \$25.50 for taxi");
      expect(e2.amount, 25.50);
    });

    test('Extracts category correctly', () {
      Expense e1 = ExpenseExtractor.extract("I spent 50 dollars on a burger.");
      expect(e1.category, "Food");

      Expense e2 = ExpenseExtractor.extract("Paid \$25.50 for flight");
      expect(e2.category, "Travel");

      Expense e3 = ExpenseExtractor.extract("Bought a new shirt");
      expect(e3.category, "Shopping");

      Expense e4 = ExpenseExtractor.extract("Random expense here");
      expect(e4.category, "Other");
    });

    test('Extracts datetime relative strings correctly', () {
      Expense e1 = ExpenseExtractor.extract("I spent 50 dollars yesterday.");
      DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(e1.date.day, yesterday.day);
      expect(e1.date.month, yesterday.month);
    });

    test('Extracts specific times correctly', () {
      Expense e1 = ExpenseExtractor.extract("I spent 50 dollars at 5pm.");
      expect(e1.date.hour, 17);
      expect(e1.date.minute, 0);

      Expense e2 = ExpenseExtractor.extract("Spent forty at 10:30 am");
      expect(e2.date.hour, 10);
      expect(e2.date.minute, 30);
    });
  });
}
