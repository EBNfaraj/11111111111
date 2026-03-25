class TruckSale {
  final int? id;
  final int quantity;
  final double pricePerTruck;
  final double? totalPrice;
  final String date;
  final String? notes;

  TruckSale({
    this.id,
    required this.quantity,
    required this.pricePerTruck,
    this.totalPrice,
    required this.date,
    this.notes,
  });

  double get calculatedTotalPrice => quantity * pricePerTruck;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'price_per_truck': pricePerTruck,
      'total_price': totalPrice ?? calculatedTotalPrice,
      'date': date,
      'notes': notes,
    };
  }

  factory TruckSale.fromMap(Map<String, dynamic> map) {
    return TruckSale(
      id: map['id'],
      quantity: map['quantity'],
      pricePerTruck: map['price_per_truck'],
      totalPrice: map['total_price'],
      date: map['date'],
      notes: map['notes'],
    );
  }
}
