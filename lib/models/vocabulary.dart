/// Represents a vocabulary item for language learning
class Vocabulary {
  final int? id;
  final String language; // 'en' for English, 'cn' for Chinese
  final String word;
  final String? pinyin; // Only for Chinese
  final String meaningVi;
  final String? exampleSentence;
  final int difficulty; // 1-5 scale
  final int timesCorrect;
  final int timesShown;
  final DateTime? lastShown;
  final DateTime createdAt;

  Vocabulary({
    this.id,
    required this.language,
    required this.word,
    this.pinyin,
    required this.meaningVi,
    this.exampleSentence,
    this.difficulty = 1,
    this.timesCorrect = 0,
    this.timesShown = 0,
    this.lastShown,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate success rate
  double get successRate {
    if (timesShown == 0) return 0.0;
    return timesCorrect / timesShown;
  }

  /// Determine if this item needs more practice (low success rate)
  bool get needsPractice => successRate < 0.6 || timesShown < 3;

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'word': word,
      'pinyin': pinyin,
      'meaning_vi': meaningVi,
      'example_sentence': exampleSentence,
      'difficulty': difficulty,
      'times_correct': timesCorrect,
      'times_shown': timesShown,
      'last_shown': lastShown?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database Map
  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id'] as int?,
      language: map['language'] as String,
      word: map['word'] as String,
      pinyin: map['pinyin'] as String?,
      meaningVi: map['meaning_vi'] as String,
      exampleSentence: map['example_sentence'] as String?,
      difficulty: map['difficulty'] as int? ?? 1,
      timesCorrect: map['times_correct'] as int? ?? 0,
      timesShown: map['times_shown'] as int? ?? 0,
      lastShown: map['last_shown'] != null
          ? DateTime.parse(map['last_shown'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create a copy with updated fields
  Vocabulary copyWith({
    int? id,
    String? language,
    String? word,
    String? pinyin,
    String? meaningVi,
    String? exampleSentence,
    int? difficulty,
    int? timesCorrect,
    int? timesShown,
    DateTime? lastShown,
    DateTime? createdAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      language: language ?? this.language,
      word: word ?? this.word,
      pinyin: pinyin ?? this.pinyin,
      meaningVi: meaningVi ?? this.meaningVi,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      difficulty: difficulty ?? this.difficulty,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesShown: timesShown ?? this.timesShown,
      lastShown: lastShown ?? this.lastShown,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Vocabulary(id: $id, language: $language, word: $word, meaningVi: $meaningVi)';
  }
}
