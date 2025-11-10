/// Quiz mode settings
enum QuizMode {
  language,
  knowledge,
  both;

  String toJson() => name;

  static QuizMode fromJson(String json) {
    return QuizMode.values.firstWhere(
      (mode) => mode.name == json,
      orElse: () => QuizMode.both,
    );
  }
}

/// Application settings
class AppSettings {
  final int reminderIntervalHours;
  final int activeHoursStart;
  final int activeHoursEnd;
  final QuizMode quizMode;
  final bool isDarkMode;
  final int questionsPerSession;
  final String ollamaModel;
  final String ollamaEndpoint;

  AppSettings({
    this.reminderIntervalHours = 2,
    this.activeHoursStart = 8,
    this.activeHoursEnd = 22,
    this.quizMode = QuizMode.both,
    this.isDarkMode = false,
    this.questionsPerSession = 3,
    this.ollamaModel = 'phi3',
    this.ollamaEndpoint = 'http://localhost:11434',
  });

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'reminder_interval_hours': reminderIntervalHours,
      'active_hours_start': activeHoursStart,
      'active_hours_end': activeHoursEnd,
      'quiz_mode': quizMode.toJson(),
      'is_dark_mode': isDarkMode ? 1 : 0,
      'questions_per_session': questionsPerSession,
      'ollama_model': ollamaModel,
      'ollama_endpoint': ollamaEndpoint,
    };
  }

  /// Create from Map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      reminderIntervalHours: map['reminder_interval_hours'] as int? ?? 2,
      activeHoursStart: map['active_hours_start'] as int? ?? 8,
      activeHoursEnd: map['active_hours_end'] as int? ?? 22,
      quizMode: QuizMode.fromJson(map['quiz_mode'] as String? ?? 'both'),
      isDarkMode: (map['is_dark_mode'] as int? ?? 0) == 1,
      questionsPerSession: map['questions_per_session'] as int? ?? 3,
      ollamaModel: map['ollama_model'] as String? ?? 'phi3',
      ollamaEndpoint: map['ollama_endpoint'] as String? ?? 'http://localhost:11434',
    );
  }

  /// Create a copy with updated fields
  AppSettings copyWith({
    int? reminderIntervalHours,
    int? activeHoursStart,
    int? activeHoursEnd,
    QuizMode? quizMode,
    bool? isDarkMode,
    int? questionsPerSession,
    String? ollamaModel,
    String? ollamaEndpoint,
  }) {
    return AppSettings(
      reminderIntervalHours: reminderIntervalHours ?? this.reminderIntervalHours,
      activeHoursStart: activeHoursStart ?? this.activeHoursStart,
      activeHoursEnd: activeHoursEnd ?? this.activeHoursEnd,
      quizMode: quizMode ?? this.quizMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      questionsPerSession: questionsPerSession ?? this.questionsPerSession,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
    );
  }

  /// Check if current time is within active hours
  bool isWithinActiveHours([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    return hour >= activeHoursStart && hour < activeHoursEnd;
  }

  @override
  String toString() {
    return 'AppSettings(interval: ${reminderIntervalHours}h, mode: $quizMode, questions: $questionsPerSession)';
  }
}
