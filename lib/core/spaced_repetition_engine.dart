import 'dart:math';
import '../models/quiz_question.dart';

/// SM-2 Spaced Repetition Algorithm
/// Based on SuperMemo 2 algorithm
class SpacedRepetitionEngine {
  /// Calculate next review interval in days
  static int calculateNextInterval({
    required int currentInterval,
    required double easinessFactor,
    required int quality, // 0-5: 0=total blackout, 5=perfect response
  }) {
    // Quality < 3 means incorrect answer → restart
    if (quality < 3) {
      return 1; // Review tomorrow
    }

    // First review: 1 day
    if (currentInterval == 0) {
      return 1;
    }

    // Second review: 6 days
    if (currentInterval == 1) {
      return 6;
    }

    // Subsequent reviews: multiply by easiness factor
    return (currentInterval * easinessFactor).round();
  }

  /// Calculate new easiness factor
  static double calculateEasinessFactor({
    required double currentEF,
    required int quality, // 0-5
  }) {
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final newEF =
        currentEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    // EF should be at least 1.3
    return max(1.3, newEF);
  }

  /// Convert score (0-100) to quality (0-5)
  static int scoreToQuality(int score) {
    if (score >= 90) return 5; // Perfect
    if (score >= 80) return 4; // Good
    if (score >= 70) return 3; // Pass
    if (score >= 50) return 2; // Fail but remembered something
    if (score >= 30) return 1; // Bad
    return 0; // Total blackout
  }

  /// Get next review date
  static DateTime getNextReviewDate({
    required DateTime lastReview,
    required int intervalDays,
  }) {
    return lastReview.add(Duration(days: intervalDays));
  }

  /// Check if question is due for review
  static bool isDueForReview({
    required DateTime? lastReview,
    required int? intervalDays,
  }) {
    if (lastReview == null) return true; // Never reviewed

    final nextReview = getNextReviewDate(
      lastReview: lastReview,
      intervalDays: intervalDays ?? 1,
    );

    return DateTime.now().isAfter(nextReview);
  }

  /// Get recommended study questions (sorted by priority)
  static List<QuizQuestion> getStudyQueue(
    List<QuizQuestion> allQuestions, {
    int maxCount = 10,
  }) {
    final dueQuestions = allQuestions.where((q) {
      return isDueForReview(
        lastReview: q.lastShown,
        intervalDays: 1, // TODO: Store interval in QuizQuestion model
      );
    }).toList();

    // Sort by priority
    dueQuestions.sort((a, b) {
      // 1. Never practiced first
      if (a.timesShown == 0 && b.timesShown > 0) return -1;
      if (a.timesShown > 0 && b.timesShown == 0) return 1;

      // 2. Lower success rate first
      final aRate = a.successRate;
      final bRate = b.successRate;
      if (aRate != bRate) return aRate.compareTo(bRate);

      // 3. Longer time since last review
      if (a.lastShown == null && b.lastShown != null) return -1;
      if (a.lastShown != null && b.lastShown == null) return 1;
      if (a.lastShown != null && b.lastShown != null) {
        return a.lastShown!.compareTo(b.lastShown!);
      }

      return 0;
    });

    return dueQuestions.take(maxCount).toList();
  }
}
