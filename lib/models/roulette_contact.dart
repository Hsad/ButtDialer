/// A contact selected for the phone roulette
class RouletteContact {
  final String id; // Contact ID from phone
  final String displayName;
  final String phoneNumber;
  int closeness; // 1-10, default 3

  RouletteContact({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.closeness = 3,
  });

  /// Create from database row
  factory RouletteContact.fromMap(Map<String, dynamic> map) {
    return RouletteContact(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      phoneNumber: map['phone_number'] as String,
      closeness: map['closeness'] as int? ?? 3,
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'closeness': closeness,
    };
  }

  /// Copy with optional modified fields
  RouletteContact copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    int? closeness,
  }) {
    return RouletteContact(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      closeness: closeness ?? this.closeness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouletteContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RouletteContact(id: $id, displayName: $displayName, closeness: $closeness)';
  }
}
