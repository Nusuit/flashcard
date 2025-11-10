import 'dart:math';
import '../models/vocabulary.dart';
import '../models/quiz_question.dart';
import '../models/app_settings.dart';
import '../models/quiz_history.dart';
import 'storage_manager.dart';

/// Quiz item that can be either vocabulary or knowledge question
class QuizItem {
  final dynamic item; // Either Vocabulary or QuizQuestion
  final QuizItemType type;
  final String question;
  final String answer;
  final QuestionType? questionType; // For knowledge questions
  final List<String>? options; // For multiple choice

  QuizItem({
    required this.item,
    required this.type,
    required this.question,
    required this.answer,
    this.questionType,
    this.options,
  });

  /// Get the item ID for tracking
  int get itemId {
    if (type == QuizItemType.vocabulary) {
      return (item as Vocabulary).id!;
    } else {
      return (item as QuizQuestion).id!;
    }
  }
}

/// Different quiz modes for vocabulary
enum VocabularyQuizMode {
  wordToMeaning,      // Show English/Chinese word, ask for Vietnamese meaning
  meaningToWord,      // Show Vietnamese meaning, ask for word
  pinyinToMeaning,    // For Chinese: show pinyin, ask for meaning
  pinyinToCharacter,  // For Chinese: show pinyin, ask for character
}

/// Generates and manages quiz sessions
class FlashcardEngine {
  final StorageManager _storage = StorageManager();
  final Random _random = Random();

  /// Generate a quiz session based on settings
  Future<List<QuizItem>> generateQuizSession(AppSettings settings) async {
    final items = <QuizItem>[];

    // Determine how many items to fetch from each category
    int vocabCount = 0;
    int knowledgeCount = 0;

    if (settings.quizMode == QuizMode.language) {
      vocabCount = settings.questionsPerSession;
    } else if (settings.quizMode == QuizMode.knowledge) {
      knowledgeCount = settings.questionsPerSession;
    } else {
      // Both mode: split questions
      vocabCount = (settings.questionsPerSession / 2).ceil();
      knowledgeCount = settings.questionsPerSession - vocabCount;
    }

    // Fetch vocabulary items
    if (vocabCount > 0) {
      final vocabItems = await _storage.getRandomVocabulary(
        limit: vocabCount,
        prioritizeWeak: true,
      );

      for (var vocab in vocabItems) {
        items.add(_createVocabularyQuiz(vocab));
      }
    }

    // Fetch knowledge questions
    if (knowledgeCount > 0) {
      final questions = await _storage.getRandomQuestions(
        limit: knowledgeCount,
        prioritizeWeak: true,
      );

      for (var question in questions) {
        items.add(_createKnowledgeQuiz(question));
      }
    }

    // Shuffle items
    items.shuffle(_random);

    return items;
  }

  /// Create a quiz item from vocabulary
  QuizItem _createVocabularyQuiz(Vocabulary vocab) {
    // Randomly select quiz mode
    VocabularyQuizMode mode;
    
    if (vocab.language == 'cn' && vocab.pinyin != null) {
      // For Chinese, include pinyin-based modes
      final modes = [
        VocabularyQuizMode.wordToMeaning,
        VocabularyQuizMode.meaningToWord,
        VocabularyQuizMode.pinyinToMeaning,
        VocabularyQuizMode.pinyinToCharacter,
      ];
      mode = modes[_random.nextInt(modes.length)];
    } else {
      // For English, only word-meaning modes
      final modes = [
        VocabularyQuizMode.wordToMeaning,
        VocabularyQuizMode.meaningToWord,
      ];
      mode = modes[_random.nextInt(modes.length)];
    }

    String question;
    String answer;

    switch (mode) {
      case VocabularyQuizMode.wordToMeaning:
        question = 'What does "${vocab.word}" mean?';
        answer = vocab.meaningVi;
        break;
      case VocabularyQuizMode.meaningToWord:
        final langName = vocab.language == 'en' ? 'English' : 'Chinese';
        question = 'Translate to $langName: ${vocab.meaningVi}';
        answer = vocab.word;
        break;
      case VocabularyQuizMode.pinyinToMeaning:
        question = 'What does "${vocab.pinyin}" mean?';
        answer = vocab.meaningVi;
        break;
      case VocabularyQuizMode.pinyinToCharacter:
        question = 'Write the Chinese character for "${vocab.pinyin}"';
        answer = vocab.word;
        break;
    }

    // Add example sentence hint if available
    if (vocab.exampleSentence != null && vocab.exampleSentence!.isNotEmpty) {
      question += '\n\nExample: ${vocab.exampleSentence}';
    }

    return QuizItem(
      item: vocab,
      type: QuizItemType.vocabulary,
      question: question,
      answer: answer,
    );
  }

  /// Create a quiz item from knowledge question
  QuizItem _createKnowledgeQuiz(QuizQuestion question) {
    return QuizItem(
      item: question,
      type: QuizItemType.knowledge,
      question: question.question,
      answer: question.answer,
      questionType: question.questionType,
      options: question.options,
    );
  }

  /// Record answer and update statistics
  Future<void> recordAnswer({
    required QuizItem quizItem,
    required bool wasCorrect,
  }) async {
    // Save to history
    await _storage.insertQuizHistory(
      QuizHistory(
        itemType: quizItem.type,
        itemId: quizItem.itemId,
        wasCorrect: wasCorrect,
      ),
    );

    // Update item statistics
    if (quizItem.type == QuizItemType.vocabulary) {
      final vocab = quizItem.item as Vocabulary;
      final updated = vocab.copyWith(
        timesShown: vocab.timesShown + 1,
        timesCorrect: vocab.timesCorrect + (wasCorrect ? 1 : 0),
        lastShown: DateTime.now(),
      );
      await _storage.updateVocabulary(updated);
    } else {
      final question = quizItem.item as QuizQuestion;
      final updated = question.copyWith(
        timesShown: question.timesShown + 1,
        timesCorrect: question.timesCorrect + (wasCorrect ? 1 : 0),
        lastShown: DateTime.now(),
      );
      await _storage.updateQuizQuestion(updated);
    }
  }

  /// Check if user answer is correct (case-insensitive, trimmed)
  bool checkAnswer(String userAnswer, String correctAnswer) {
    final normalized1 = userAnswer.trim().toLowerCase();
    final normalized2 = correctAnswer.trim().toLowerCase();
    
    // Exact match
    if (normalized1 == normalized2) return true;
    
    // Allow for minor variations (e.g., "an apple" vs "apple")
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      // Check if the difference is only articles or small words
      final words1 = normalized1.split(' ');
      final words2 = normalized2.split(' ');
      final smallWords = {'a', 'an', 'the', 'to', 'is', 'are'};
      
      final filtered1 = words1.where((w) => !smallWords.contains(w)).toList();
      final filtered2 = words2.where((w) => !smallWords.contains(w)).toList();
      
      if (filtered1.join(' ') == filtered2.join(' ')) return true;
    }
    
    return false;
  }

  /// Get similarity score (0-1) for partial credit
  double getSimilarity(String userAnswer, String correctAnswer) {
    final normalized1 = userAnswer.trim().toLowerCase();
    final normalized2 = correctAnswer.trim().toLowerCase();
    
    if (normalized1 == normalized2) return 1.0;
    
    // Levenshtein distance
    final distance = _levenshteinDistance(normalized1, normalized2);
    final maxLength = max(normalized1.length, normalized2.length);
    
    if (maxLength == 0) return 1.0;
    
    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Get performance summary
  Future<Map<String, dynamic>> getPerformanceSummary() async {
    final stats = await _storage.getStatistics();
    final counts = await _storage.getCounts();
    
    return {
      ...stats,
      ...counts,
    };
  }
}
