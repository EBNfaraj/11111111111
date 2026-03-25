class House {
  final int? id;
  final String ownerName;
  final String? meterNumber;
  final bool isActive;

  House({
    this.id,
    required this.ownerName,
    this.meterNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_name': ownerName,
      'meter_number': meterNumber,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'],
      ownerName: map['owner_name'],
      meterNumber: map['meter_number'],
      isActive: map['is_active'] == 1,
    );
  }
}
