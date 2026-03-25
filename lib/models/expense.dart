class Expense {
  final int? id;
  final String category;
  final String? description;
  final double amount;
  final String date;

  Expense({
    this.id,
    required this.category,
    this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'] ?? 'أخرى',
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
    );
  }
}
