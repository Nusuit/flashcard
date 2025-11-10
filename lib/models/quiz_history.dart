/// Type of quiz item
enum QuizItemType {
  vocabulary,
  knowledge;

  String toJson() => name;

  static QuizItemType fromJson(String json) {
    return QuizItemType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => QuizItemType.vocabulary,
    );
  }
}

/// Records quiz history for analytics
class QuizHistory {
  final int? id;
  final QuizItemType itemType;
  final int itemId;
  final bool wasCorrect;
  final DateTime answeredAt;

  QuizHistory({
    this.id,
    required this.itemType,
    required this.itemId,
    required this.wasCorrect,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_type': itemType.toJson(),
      'item_id': itemId,
      'was_correct': wasCorrect ? 1 : 0,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory QuizHistory.fromMap(Map<String, dynamic> map) {
    return QuizHistory(
      id: map['id'] as int?,
      itemType: QuizItemType.fromJson(map['item_type'] as String),
      itemId: map['item_id'] as int,
      wasCorrect: (map['was_correct'] as int) == 1,
      answeredAt: DateTime.parse(map['answered_at'] as String),
    );
  }

  @override
  String toString() {
    return 'QuizHistory(type: $itemType, itemId: $itemId, correct: $wasCorrect)';
  }
}
