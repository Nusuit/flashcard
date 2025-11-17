import 'dart:async';
import 'package:flutter/material.dart';
import '../core/storage_manager.dart';
import '../core/quiz_event_bus.dart';
import '../core/quiz_queue_builder.dart';
import '../models/quiz_question.dart';
import '../models/knowledge.dart';
import '../models/quiz_settings.dart';
import '../models/quiz_queue_item.dart';

/// Service to schedule and manage background quiz popups
class QuizScheduler {
  static final QuizScheduler _instance = QuizScheduler._internal();
  factory QuizScheduler() => _instance;
  QuizScheduler._internal();

  Timer? _timer;
  final StorageManager _storageManager = StorageManager();
  final QuizEventBus _eventBus = QuizEventBus();
  final QuizQueueBuilder _queueBuilder = QuizQueueBuilder();
  QuizSettings _settings = QuizSettings();
  DateTime _lastActivity = DateTime.now();

  // Cache to reduce database queries
  List<Knowledge>? _cachedKnowledge;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Prevent concurrent quiz triggers
  bool _isProcessingQuiz = false;

  QuizSettings get settings => _settings;
  QuizEventBus get eventBus => _eventBus;

  /// Start the quiz scheduler
  void start({Duration? interval, QuizSettings? settings}) {
    if (settings != null) {
      _settings = settings;
    }

    if (!_settings.enabled) {
      stop();
      return;
    }

    stop(); // Stop any existing timer

    final effectiveInterval = interval ?? _settings.interval;

    _timer = Timer.periodic(effectiveInterval, (timer) {
      // Non-blocking: fire and forget
      _checkAndScheduleQuiz();
    });

    // Schedule first quiz immediately
    _checkAndScheduleQuiz();
  }

  /// Stop the quiz scheduler
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pause quiz scheduling
  void pause() {
    _eventBus.fire(QuizEvent(QuizEventType.quizPaused));
  }

  /// Resume quiz scheduling
  void resume() {
    _eventBus.fire(QuizEvent(QuizEventType.quizResumed));
  }

  /// Record user activity for idle detection
  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check if user is idle
  bool get isIdle {
    final idleDuration = DateTime.now().difference(_lastActivity);
    return idleDuration.inMinutes >= _settings.idleMinutes;
  }

  /// Check if it's time for a quiz and schedule one
  Future<void> _checkAndScheduleQuiz() async {
    // Prevent concurrent execution
    if (_isProcessingQuiz) return;
    _isProcessingQuiz = true;

    try {
      // Check settings
      if (!_settings.enabled) return;
      if (_settings.onlyWhenIdle && !isIdle) return;

      // Get knowledge with caching
      final knowledgeList = await _getCachedKnowledge();
      if (knowledgeList.isEmpty) return;

      // Filter knowledge items that have reminder time
      final activeKnowledge = knowledgeList.where((k) {
        if (k.reminderTime == null) return false;

        // Check if reminder time has passed
        final now = DateTime.now();
        final reminderDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          k.reminderTime!.hour,
          k.reminderTime!.minute,
        );

        return now.isAfter(reminderDateTime);
      }).toList();

      if (activeKnowledge.isEmpty) return;

      // Select a random knowledge item
      activeKnowledge.shuffle();
      final selectedKnowledge = activeKnowledge.first;

      // Get or generate a question for this knowledge
      final question = await _getOrGenerateQuestion(selectedKnowledge);
      if (question == null) return;

      // Fire event instead of callback
      _eventBus.fire(QuizEvent(
        QuizEventType.quizReady,
        data: {
          'question': question,
          'knowledge': selectedKnowledge,
        },
      ));
    } catch (e) {
      debugPrint('Quiz Scheduler Error: $e');
    } finally {
      _isProcessingQuiz = false;
    }
  }

  /// Get knowledge list with caching
  Future<List<Knowledge>> _getCachedKnowledge() async {
    final now = DateTime.now();

    // Return cache if still valid
    if (_cachedKnowledge != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < _cacheExpiry) {
      return _cachedKnowledge!;
    }

    // Refresh cache
    _cachedKnowledge = await _storageManager.getAllKnowledge();
    _cacheTimestamp = now;
    return _cachedKnowledge!;
  }

  /// Clear knowledge cache (call when knowledge is added/updated)
  void clearCache() {
    _cachedKnowledge = null;
    _cacheTimestamp = null;
  }

  /// Get an existing question or generate a new one
  Future<QuizQuestion?> _getOrGenerateQuestion(Knowledge knowledge) async {
    try {
      // Use quiz queue for instant retrieval
      final queueItem = await _storageManager.getNextQuizFromQueue();

      if (queueItem != null && queueItem.knowledgeId == knowledge.id) {
        // Get the actual question
        final questions =
            await _storageManager.getQuestionsByKnowledgeId(knowledge.id!);
        return questions.firstWhere(
          (q) => q.id == queueItem.questionId,
          orElse: () => questions.first,
        );
      }

      // Fallback: old method if queue is empty
      final questions =
          await _storageManager.getQuestionsByKnowledgeId(knowledge.id!);

      if (questions.isEmpty) {
        return null;
      }

      questions.sort((a, b) {
        if (a.needsPractice && !b.needsPractice) return -1;
        if (!a.needsPractice && b.needsPractice) return 1;
        return a.timesShown.compareTo(b.timesShown);
      });

      return questions.first;
    } catch (e) {
      debugPrint('Error getting/generating question: $e');
      return null;
    }
  }

  /// Manually trigger a quiz for testing
  ///
  /// API Test:
  /// ```dart
  /// // Random quiz
  /// await QuizScheduler().triggerQuiz();
  /// // Listen: QuizEventBus for QuizEvent with question data
  ///
  /// // Specific knowledge
  /// await QuizScheduler().triggerQuiz(knowledgeId: 1);
  /// ```
  ///
  /// Performance: 5-10ms using queue, fires QuizEvent with {question, knowledge, queueItemId}
  Future<void> triggerQuiz({int? knowledgeId}) async {
    debugPrint('┌─ TRIGGER QUIZ START ─────────────────────');
    debugPrint('│ Knowledge ID: $knowledgeId');
    debugPrint('│ Processing: $_isProcessingQuiz');

    // Prevent concurrent triggers
    if (_isProcessingQuiz) {
      debugPrint('│ ❌ Already processing, aborting');
      debugPrint('└──────────────────────────────────────────');
      return;
    }
    _isProcessingQuiz = true;

    try {
      debugPrint('│ 📥 Fetching quiz from queue...');
      // Get next quiz from queue (instant!)
      final queueItem = knowledgeId != null
          ? (await _storageManager.getStudySession(knowledgeId, limit: 1))
              .firstOrNull
          : await _storageManager.getNextQuizFromQueue();

      if (queueItem == null) {
        debugPrint('│ ❌ No quiz available in queue');
        debugPrint('└──────────────────────────────────────────');
        _isProcessingQuiz = false;
        return;
      }

      debugPrint('│ ✓ Queue item found: ID=${queueItem.id}');
      debugPrint('│   Knowledge ID: ${queueItem.knowledgeId}');
      debugPrint('│   Question ID: ${queueItem.questionId}');
      debugPrint('│ 📥 Fetching question...');

      // Get the question and knowledge
      final questions = await _storageManager
          .getQuestionsByKnowledgeId(queueItem.knowledgeId);

      debugPrint('│ ✓ Found ${questions.length} questions');

      final question =
          questions.firstWhere((q) => q.id == queueItem.questionId);
      debugPrint('│ ✓ Question found: "${question.question}"');

      debugPrint('│ 📥 Fetching knowledge...');
      final knowledge =
          await _storageManager.getKnowledgeById(queueItem.knowledgeId);

      if (knowledge == null) {
        debugPrint('│ ❌ Knowledge not found');
        debugPrint('└──────────────────────────────────────────');
        _isProcessingQuiz = false;
        return;
      }

      debugPrint('│ ✓ Knowledge found: "${knowledge.topic}"');
      debugPrint('│ 🔥 Firing QuizEvent...');

      _eventBus.fire(QuizEvent(
        QuizEventType.quizReady,
        data: {
          'question': question,
          'knowledge': knowledge,
          'queueItemId': queueItem.id, // Important for updating after answer
        },
      ));

      debugPrint('│ ✓ Event fired successfully');
      debugPrint('└─ TRIGGER QUIZ COMPLETED ────────────────');
    } catch (e, stackTrace) {
      debugPrint('│ ❌ ERROR: $e');
      debugPrint('│ Stack: $stackTrace');
      debugPrint('└──────────────────────────────────────────');
    } finally {
      _isProcessingQuiz = false;
    }
  }

  /// Update quiz settings
  void updateSettings(QuizSettings newSettings) {
    _settings = newSettings;
    if (_settings.enabled && _timer == null) {
      start();
    } else if (!_settings.enabled && _timer != null) {
      stop();
    } else if (_timer != null) {
      // Restart with new interval
      start();
    }
  }

  /// Update quiz interval (legacy method)
  void updateInterval(Duration newInterval) {
    _settings = _settings.copyWith(interval: newInterval);
    if (_timer != null) {
      start();
    }
  }
}
