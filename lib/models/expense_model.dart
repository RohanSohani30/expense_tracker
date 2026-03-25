class Expense {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final String description;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, date: $date, description: $description)';
  }
}
