import 'dart:convert';

/// Question types for quiz
enum QuestionType {
  open,
  multipleChoice,
  trueFalse;

  String toJson() => name;

  static QuestionType fromJson(String json) {
    return QuestionType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => QuestionType.open,
    );
  }
}

/// Represents a quiz question generated from knowledge notes
class QuizQuestion {
  final int? id;
  final int? knowledgeId;
  final String question;
  final String answer;
  final QuestionType questionType;
  final List<String>? options; // For multiple choice
  final int timesCorrect;
  final int timesShown;
  final DateTime? lastShown;

  QuizQuestion({
    this.id,
    this.knowledgeId,
    required this.question,
    required this.answer,
    this.questionType = QuestionType.open,
    this.options,
    this.timesCorrect = 0,
    this.timesShown = 0,
    this.lastShown,
  });

  /// Calculate success rate
  double get successRate {
    if (timesShown == 0) return 0.0;
    return timesCorrect / timesShown;
  }

  /// Determine if this question needs more practice
  bool get needsPractice => successRate < 0.6 || timesShown < 3;

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'knowledge_id': knowledgeId,
      'question': question,
      'answer': answer,
      'question_type': questionType.toJson(),
      'options': options != null ? jsonEncode(options) : null,
      'times_correct': timesCorrect,
      'times_shown': timesShown,
      'last_shown': lastShown?.toIso8601String(),
    };
  }

  /// Create from database Map
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int?,
      knowledgeId: map['knowledge_id'] as int?,
      question: map['question'] as String,
      answer: map['answer'] as String,
      questionType: QuestionType.fromJson(map['question_type'] as String),
      options: map['options'] != null
          ? List<String>.from(jsonDecode(map['options'] as String))
          : null,
      timesCorrect: map['times_correct'] as int? ?? 0,
      timesShown: map['times_shown'] as int? ?? 0,
      lastShown: map['last_shown'] != null
          ? DateTime.parse(map['last_shown'] as String)
          : null,
    );
  }

  /// Create a copy with updated fields
  QuizQuestion copyWith({
    int? id,
    int? knowledgeId,
    String? question,
    String? answer,
    QuestionType? questionType,
    List<String>? options,
    int? timesCorrect,
    int? timesShown,
    DateTime? lastShown,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      knowledgeId: knowledgeId ?? this.knowledgeId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesShown: timesShown ?? this.timesShown,
      lastShown: lastShown ?? this.lastShown,
    );
  }

  @override
  String toString() {
    return 'QuizQuestion(id: $id, question: $question, type: $questionType)';
  }
}
