/// Represents a quiz item in the pre-sorted queue
class QuizQueueItem {
  final int? id;
  final int knowledgeId;
  final int questionId;
  final int priority; // 0-100, higher = more urgent
  final DateTime nextReviewDate;
  final double easinessFactor; // SM-2 EF (1.3 - 2.5)
  final int currentInterval; // Days since last review
  final DateTime createdAt;

  QuizQueueItem({
    this.id,
    required this.knowledgeId,
    required this.questionId,
    required this.priority,
    required this.nextReviewDate,
    this.easinessFactor = 2.5,
    this.currentInterval = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'knowledge_id': knowledgeId,
      'question_id': questionId,
      'priority': priority,
      'next_review_date': nextReviewDate.toIso8601String(),
      'easiness_factor': easinessFactor,
      'current_interval': currentInterval,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuizQueueItem.fromMap(Map<String, dynamic> map) {
    return QuizQueueItem(
      id: map['id'] as int?,
      knowledgeId: map['knowledge_id'] as int,
      questionId: map['question_id'] as int,
      priority: map['priority'] as int,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
      easinessFactor: (map['easiness_factor'] as num?)?.toDouble() ?? 2.5,
      currentInterval: map['current_interval'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  QuizQueueItem copyWith({
    int? id,
    int? knowledgeId,
    int? questionId,
    int? priority,
    DateTime? nextReviewDate,
    double? easinessFactor,
    int? currentInterval,
    DateTime? createdAt,
  }) {
    return QuizQueueItem(
      id: id ?? this.id,
      knowledgeId: knowledgeId ?? this.knowledgeId,
      questionId: questionId ?? this.questionId,
      priority: priority ?? this.priority,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      currentInterval: currentInterval ?? this.currentInterval,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
