/// A record of a call made through the roulette
class CallLogEntry {
  final int? id;
  final String contactId;
  final String contactName;
  final DateTime timestamp;

  CallLogEntry({
    this.id,
    required this.contactId,
    required this.contactName,
    required this.timestamp,
  });

  /// Create from database row
  factory CallLogEntry.fromMap(Map<String, dynamic> map) {
    return CallLogEntry(
      id: map['id'] as int?,
      contactId: map['contact_id'] as String,
      contactName: map['contact_name'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'contact_id': contactId,
      'contact_name': contactName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'CallLogEntry(id: $id, contactName: $contactName, timestamp: $timestamp)';
  }
}
