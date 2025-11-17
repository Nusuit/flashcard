import 'dart:async';
import 'package:flutter/material.dart';
import '../core/storage_manager.dart';
import '../models/quiz_question.dart';
import '../models/knowledge.dart';

/// Service to schedule and manage background quiz popups
class QuizScheduler {
  static final QuizScheduler _instance = QuizScheduler._internal();
  factory QuizScheduler() => _instance;
  QuizScheduler._internal();

  Timer? _timer;
  final StorageManager _storageManager = StorageManager();
  Function(QuizQuestion, Knowledge)? onQuizReady;

  /// Start the quiz scheduler
  void start({Duration interval = const Duration(minutes: 30)}) {
    stop(); // Stop any existing timer

    _timer = Timer.periodic(interval, (timer) async {
      await _checkAndScheduleQuiz();
    });

    // Schedule first quiz immediately
    _checkAndScheduleQuiz();
  }

  /// Stop the quiz scheduler
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if it's time for a quiz and schedule one
  Future<void> _checkAndScheduleQuiz() async {
    try {
      // Get all knowledge items
      final knowledgeList = await _storageManager.getAllKnowledge();
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

      // Notify listeners (show quiz popup)
      if (onQuizReady != null) {
        onQuizReady!(question, selectedKnowledge);
      }
    } catch (e) {
      debugPrint('Quiz Scheduler Error: $e');
    }
  }

  /// Get an existing question or generate a new one
  Future<QuizQuestion?> _getOrGenerateQuestion(Knowledge knowledge) async {
    try {
      // Try to get questions from database
      final questions =
          await _storageManager.getQuestionsByKnowledgeId(knowledge.id!);

      if (questions.isEmpty) {
        // No questions available, need to generate
        return null; // Will be handled by LLM question generator
      }

      // Prioritize questions that need practice
      questions.sort((a, b) {
        // Sort by: needsPractice first, then by times shown (less shown = higher priority)
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
  Future<void> triggerQuiz({int? knowledgeId}) async {
    try {
      Knowledge? selectedKnowledge;

      if (knowledgeId != null) {
        selectedKnowledge = await _storageManager.getKnowledgeById(knowledgeId);
      } else {
        final knowledgeList = await _storageManager.getAllKnowledge();
        if (knowledgeList.isEmpty) return;
        knowledgeList.shuffle();
        selectedKnowledge = knowledgeList.first;
      }

      if (selectedKnowledge == null) return;

      final question = await _getOrGenerateQuestion(selectedKnowledge);
      if (question == null) return;

      if (onQuizReady != null) {
        onQuizReady!(question, selectedKnowledge);
      }
    } catch (e) {
      debugPrint('Manual Quiz Trigger Error: $e');
    }
  }

  /// Update quiz interval
  void updateInterval(Duration newInterval) {
    if (_timer != null) {
      start(interval: newInterval);
    }
  }
}
