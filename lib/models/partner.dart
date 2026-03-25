class Partner {
  final int? id;
  final String name;
  final double sharePercentage; // e.g. 50.0 for 50%
  final bool isActive;

  Partner({
    this.id,
    required this.name,
    required this.sharePercentage,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'share_percentage': sharePercentage,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'],
      name: map['name'],
      sharePercentage: map['share_percentage'] ?? 0.0,
      isActive: map['is_active'] == 1,
    );
  }
}
