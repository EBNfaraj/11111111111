class MeterReading {
  final int? id;
  final int houseId;
  final int previousReading;
  final int currentReading;
  final double pricePerUnit;
  final double? consumption;
  final double? totalPrice;
  final String date;

  MeterReading({
    this.id,
    required this.houseId,
    required this.previousReading,
    required this.currentReading,
    required this.pricePerUnit,
    this.consumption,
    this.totalPrice,
    required this.date,
  });

  double get calculatedConsumption => (currentReading - previousReading).toDouble();
  double get calculatedTotalPrice => calculatedConsumption * pricePerUnit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_id': houseId,
      'previous_reading': previousReading,
      'current_reading': currentReading,
      'price_per_unit': pricePerUnit,
      'consumption': consumption ?? calculatedConsumption,
      'total_price': totalPrice ?? calculatedTotalPrice,
      'date': date,
    };
  }

  factory MeterReading.fromMap(Map<String, dynamic> map) {
    return MeterReading(
      id: map['id'],
      houseId: map['house_id'],
      previousReading: map['previous_reading'],
      currentReading: map['current_reading'],
      pricePerUnit: map['price_per_unit'],
      consumption: map['consumption'],
      totalPrice: map['total_price'],
      date: map['date'],
    );
  }
}
