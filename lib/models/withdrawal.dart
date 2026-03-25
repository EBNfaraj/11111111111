class Withdrawal {
  final int? id;
  final int? partnerId; // If null, it means it's for a worker
  final double amount;
  final String date;
  final String? notes;

  Withdrawal({
    this.id,
    this.partnerId,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_id': partnerId,
      'amount': amount,
      'date': date,
      'notes': notes,
    };
  }

  factory Withdrawal.fromMap(Map<String, dynamic> map) {
    return Withdrawal(
      id: map['id'],
      partnerId: map['partner_id'],
      amount: map['amount'],
      date: map['date'],
      notes: map['notes'],
    );
  }
}
