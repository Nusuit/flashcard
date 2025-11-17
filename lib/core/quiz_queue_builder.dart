import 'package:flutter/foundation.dart';
import '../core/storage_manager.dart';
import '../core/gemini_service.dart';
import '../core/spaced_repetition_engine.dart';
import '../models/knowledge.dart';
import '../models/quiz_question.dart';
import '../models/quiz_queue_item.dart';

/// Background service to build and maintain quiz queue
class QuizQueueBuilder {
  static final QuizQueueBuilder _instance = QuizQueueBuilder._internal();
  factory QuizQueueBuilder() => _instance;
  QuizQueueBuilder._internal();

  final StorageManager _storage = StorageManager();
  final GeminiService _gemini = GeminiService();
  bool _isBuilding = false;

  /// Build quiz queue for a knowledge (background, non-blocking)
  ///
  /// API Test:
  /// ```dart
  /// final knowledge = Knowledge(id: 1, topic: 'Test', content: 'Content...');
  /// await QuizQueueBuilder().buildQueueForKnowledge(knowledge);
  /// // Check: SELECT COUNT(*) FROM quiz_queue WHERE knowledge_id = 1
  /// // Expected: 10 rows with priority 50-100
  /// ```
  ///
  /// Process:
  /// 1. Check if queue exists → skip if yes
  /// 2. Get questions from DB or generate via LLM (max 10)
  /// 3. Calculate SM-2 initial priority for each
  /// 4. Insert to quiz_queue table
  ///
  /// @param knowledge Knowledge object with id, topic, content
  /// @returns Future<void> (non-blocking background job)
  Future<void> buildQueueForKnowledge(Knowledge knowledge) async {
    if (_isBuilding) {
      debugPrint('Queue builder already running, skipping...');
      return;
    }

    _isBuilding = true;

    try {
      debugPrint('🔧 Building quiz queue for: ${knowledge.topic}');

      // Check if queue already exists
      final hasQueue = await _storage.hasQuizQueue(knowledge.id!);
      if (hasQueue) {
        debugPrint('✅ Queue already exists, skipping build');
        _isBuilding = false;
        return;
      }

      // 1. Get existing questions or generate new ones
      List<QuizQuestion> questions =
          await _storage.getQuestionsByKnowledgeId(knowledge.id!);

      if (questions.isEmpty) {
        // Check if content is valid
        if (knowledge.content.trim().isEmpty) {
          debugPrint('⚠️ Content is empty, cannot generate questions');
          _isBuilding = false;
          return;
        }

        // Handle vocabulary mode differently
        if (knowledge.mode == 'vocabulary') {
          debugPrint(
              '📚 Vocabulary mode detected, creating simple flashcards...');

          // Parse content as vocabulary list (word: meaning format)
          final lines = knowledge.content
              .split('\n')
              .where((line) => line.trim().isNotEmpty);

          for (var line in lines) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final word = parts[0].trim();
              final meaning = parts.sublist(1).join(':').trim();

              final question = QuizQuestion(
                knowledgeId: knowledge.id!,
                question: 'What is the meaning of "$word"?',
                answer: meaning,
                questionType: QuestionType.open,
              );

              final qId = await _storage.insertQuizQuestion(question);
              questions.add(question.copyWith(id: qId));
            }
          }

          if (questions.isEmpty) {
            debugPrint('⚠️ Could not create vocabulary questions from content');
            debugPrint('💡 Hint: Content should be in format "word: meaning"');
            _isBuilding = false;
            return;
          }

          debugPrint('✅ Created ${questions.length} vocabulary flashcards');
        } else {
          // Normal mode: Use Gemini
          debugPrint('📝 No questions found, generating from content...');
          debugPrint(
              '📝 Content preview: ${knowledge.content.substring(0, knowledge.content.length > 100 ? 100 : knowledge.content.length)}...');

          // Generate questions from PDF content
          final contentToSend = knowledge.content.substring(
              0,
              knowledge.content.length > 3000
                  ? 3000
                  : knowledge.content.length);

          debugPrint('📝 Sending ${contentToSend.length} chars to Gemini...');
          final generatedQuestions =
              await _gemini.generateFlashcardsFromPdf(contentToSend);

          if (generatedQuestions.isEmpty) {
            debugPrint('⚠️ Failed to generate questions');
            _isBuilding = false;
            return;
          }

          // Save generated questions to database
          for (var qData in generatedQuestions) {
            final question = QuizQuestion(
              knowledgeId: knowledge.id!,
              question: qData['question'] as String,
              answer: qData['answer'] as String,
              questionType: QuestionType.values.firstWhere(
                (e) =>
                    e.toString().split('.').last ==
                    (qData['type'] as String? ?? 'open'),
                orElse: () => QuestionType.open,
              ),
              options: qData['options'] != null
                  ? (qData['options'] as List).map((e) => e.toString()).toList()
                  : null,
            );

            final qId = await _storage.insertQuizQuestion(question);
            questions.add(question.copyWith(id: qId));
          }

          debugPrint('✅ Generated and saved ${questions.length} questions');
        }
      }

      // 2. Build queue items with SM-2 priorities
      for (var question in questions) {
        final priority = _calculateInitialPriority(question);

        final queueItem = QuizQueueItem(
          knowledgeId: knowledge.id!,
          questionId: question.id!,
          priority: priority,
          nextReviewDate: DateTime.now(), // Available immediately
          easinessFactor: 2.5, // Default SM-2 EF
          currentInterval: 0, // New question
        );

        await _storage.insertQuizQueue(queueItem);
      }

      debugPrint('✅ Quiz queue built: ${questions.length} items');
    } catch (e) {
      debugPrint('❌ Error building queue: $e');
    } finally {
      _isBuilding = false;
    }
  }

  /// Calculate initial priority for new question
  int _calculateInitialPriority(QuizQuestion question) {
    // New questions get high priority
    if (question.timesShown == 0) {
      return 100;
    }

    // Adjust based on success rate
    if (question.needsPractice) {
      return 80 + (20 * (1 - question.successRate)).round();
    }

    return 50 + (50 * (1 - question.successRate)).round();
  }

  /// Rebuild queue for existing knowledge (e.g., after manual question add)
  ///
  /// API Test:
  /// ```dart
  /// await QuizQueueBuilder().rebuildQueue(knowledgeId: 1);
  /// // Check: SELECT COUNT(*) FROM quiz_queue WHERE knowledge_id = 1
  /// // Expected: Fresh queue with updated priorities
  /// ```
  ///
  /// Process: Delete old queue → Rebuild from scratch
  Future<void> rebuildQueue(int knowledgeId) async {
    try {
      // Delete existing queue
      await _storage.deleteQuizQueueByKnowledge(knowledgeId);

      // Get knowledge and rebuild
      final knowledge = await _storage.getKnowledgeById(knowledgeId);
      if (knowledge != null) {
        await buildQueueForKnowledge(knowledge);
      }
    } catch (e) {
      debugPrint('Error rebuilding queue: $e');
    }
  }

  /// Update queue item after user answers
  ///
  /// API Test:
  /// ```dart
  /// // Correct answer
  /// await QuizQueueBuilder().updateAfterAnswer(queueId: 5, score: 90, isCorrect: true);
  /// // Check: SELECT easiness_factor, current_interval FROM quiz_queue WHERE id = 5
  /// // Expected: EF ≈ 2.6, interval = 1 or 6 days
  ///
  /// // Wrong answer
  /// await QuizQueueBuilder().updateAfterAnswer(queueId: 5, score: 30, isCorrect: false);
  /// // Expected: EF ≈ 2.3, interval = 1, priority = 95-100
  /// ```
  Future<void> updateAfterAnswer(int queueId, int score, bool isCorrect) async {
    try {
      final item = await _storage.getQuizQueueById(queueId);
      if (item == null) return;

      // Calculate SM-2 values
      final quality = SpacedRepetitionEngine.scoreToQuality(score);

      final newEF = SpacedRepetitionEngine.calculateEasinessFactor(
        currentEF: item.easinessFactor,
        quality: quality,
      );

      final newInterval = SpacedRepetitionEngine.calculateNextInterval(
        currentInterval: item.currentInterval,
        easinessFactor: newEF,
        quality: quality,
      );

      final nextReviewDate = SpacedRepetitionEngine.getNextReviewDate(
        lastReview: DateTime.now(),
        intervalDays: newInterval,
      );

      // Calculate new priority
      final newPriority =
          _calculatePriority(score, newInterval, item.currentInterval);

      // Update queue item
      final updatedItem = item.copyWith(
        priority: newPriority,
        easinessFactor: newEF,
        currentInterval: newInterval,
        nextReviewDate: nextReviewDate,
      );

      await _storage.updateQuizQueue(updatedItem);

      debugPrint(
          '✅ Updated queue item: priority=$newPriority, interval=$newInterval days, nextReview=${nextReviewDate.toString().substring(0, 10)}');
    } catch (e) {
      debugPrint('Error updating queue after answer: $e');
    }
  }

  /// Calculate priority based on performance
  int _calculatePriority(int score, int interval, int currentInterval) {
    // Low score = high priority (needs review soon)
    if (score < 60) {
      return 90 + (10 * (60 - score) ~/ 60);
    }

    // Medium score = medium priority
    if (score < 80) {
      return 60 + (30 * (80 - score) ~/ 20);
    }

    // High score = lower priority (reviewed well)
    // But increase priority as review date approaches
    final basePriority = 30 + (30 * (100 - score) ~/ 20);

    // Boost priority if interval is long (needs review)
    if (interval > 7) {
      return (basePriority + 20).clamp(0, 100);
    }

    return basePriority.clamp(0, 100);
  }

  /// Get queue status for a knowledge
  ///
  /// API Test:
  /// ```dart
  /// final status = await QuizQueueBuilder().getQueueStatus(knowledgeId: 1);
  /// print('Total: ${status['total']}, Due: ${status['due']}, Avg Priority: ${status['avgPriority']}');
  /// // Expected: {total: 10, due: 3, avgPriority: 75}
  /// ```
  Future<Map<String, dynamic>> getQueueStatus(int knowledgeId) async {
    final session = await _storage.getStudySession(knowledgeId, limit: 100);

    final dueCount = session.where((item) {
      return item.nextReviewDate.isBefore(DateTime.now());
    }).length;

    final avgPriority = session.isEmpty
        ? 0
        : session.map((e) => e.priority).reduce((a, b) => a + b) /
            session.length;

    return {
      'total': session.length,
      'due': dueCount,
      'avgPriority': avgPriority.round(),
    };
  }
}
