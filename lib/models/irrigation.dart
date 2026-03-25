class Irrigation {
  final int? id;
  final String date;
  final double hours;
  final double pricePerHour;
  final double? totalPrice;
  final String? notes;

  Irrigation({
    this.id,
    required this.date,
    required this.hours,
    required this.pricePerHour,
    this.totalPrice,
    this.notes,
  });

  double get calculatedTotalPrice => hours * pricePerHour;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'hours': hours,
      'price_per_hour': pricePerHour,
      'total_price': totalPrice ?? calculatedTotalPrice,
      'notes': notes,
    };
  }

  factory Irrigation.fromMap(Map<String, dynamic> map) {
    return Irrigation(
      id: map['id'],
      date: map['date'],
      hours: map['hours'],
      pricePerHour: map['price_per_hour'],
      totalPrice: map['total_price'],
      notes: map['notes'],
    );
  }
}
