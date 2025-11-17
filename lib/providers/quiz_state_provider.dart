import 'package:flutter/foundation.dart';
import '../models/quiz_question.dart';
import '../models/knowledge.dart';

/// Quiz state management using ChangeNotifier
class QuizStateProvider extends ChangeNotifier {
  QuizQuestion? _currentQuiz;
  Knowledge? _currentKnowledge;
  bool _isPaused = false;
  int _sessionQuestionsCount = 0;
  int _sessionCorrectCount = 0;

  QuizQuestion? get currentQuiz => _currentQuiz;
  Knowledge? get currentKnowledge => _currentKnowledge;
  bool get isPaused => _isPaused;
  int get sessionQuestionsCount => _sessionQuestionsCount;
  int get sessionCorrectCount => _sessionCorrectCount;
  double get sessionSuccessRate => _sessionQuestionsCount > 0
      ? _sessionCorrectCount / _sessionQuestionsCount
      : 0.0;

  void setQuiz(QuizQuestion question, Knowledge knowledge) {
    _currentQuiz = question;
    _currentKnowledge = knowledge;
    notifyListeners();
  }

  void clearQuiz() {
    _currentQuiz = null;
    _currentKnowledge = null;
    notifyListeners();
  }

  void pauseQuiz() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeQuiz() {
    _isPaused = false;
    notifyListeners();
  }

  void recordAnswer(bool isCorrect) {
    _sessionQuestionsCount++;
    if (isCorrect) _sessionCorrectCount++;
    notifyListeners();
  }

  void resetSession() {
    _sessionQuestionsCount = 0;
    _sessionCorrectCount = 0;
    notifyListeners();
  }
}
