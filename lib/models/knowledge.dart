/// Represents a custom knowledge note
class Knowledge {
  final int? id;
  final String topic;
  final String content;
  final DateTime createdAt;

  Knowledge({
    this.id,
    required this.topic,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory Knowledge.fromMap(Map<String, dynamic> map) {
    return Knowledge(
      id: map['id'] as int?,
      topic: map['topic'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create a copy with updated fields
  Knowledge copyWith({
    int? id,
    String? topic,
    String? content,
    DateTime? createdAt,
  }) {
    return Knowledge(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Knowledge(id: $id, topic: $topic)';
  }
}
