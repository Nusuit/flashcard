import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../core/flashcard_engine.dart';

class QuizScreen extends StatefulWidget {
  final AppSettings settings;

  const QuizScreen({super.key, required this.settings});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FlashcardEngine _engine = FlashcardEngine();
  final TextEditingController _answerController = TextEditingController();
  
  List<QuizItem> _quizItems = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;
  String? _userAnswer;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    
    try {
      final items = await _engine.generateQuizSession(widget.settings);
      setState(() {
        _quizItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quiz: $e')),
      );
    }
  }

  QuizItem get _currentItem => _quizItems[_currentIndex];
  bool get _isLastQuestion => _currentIndex >= _quizItems.length - 1;

  void _showAnswerPressed() {
    setState(() {
      _showAnswer = true;
      _userAnswer = _answerController.text;
    });
  }

  Future<void> _submitAnswer(bool isCorrect) async {
    // Record the answer
    await _engine.recordAnswer(
      quizItem: _currentItem,
      wasCorrect: isCorrect,
    );

    if (isCorrect) {
      _correctCount++;
    }

    // Move to next question or finish
    if (_isLastQuestion) {
      _showResults();
    } else {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _userAnswer = null;
        _answerController.clear();
      });
    }
  }

  void _showResults() {
    final accuracy = (_correctCount / _quizItems.length * 100).round();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You got $_correctCount out of ${_quizItems.length} correct',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              value: _correctCount / _quizItems.length,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '$accuracy%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accuracy >= 70 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close quiz screen
            },
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _restartQuiz();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _userAnswer = null;
      _correctCount = 0;
      _answerController.clear();
    });
    _loadQuiz();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Quiz...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No quiz items available'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${_quizItems.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_correctCount/${_currentIndex}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _quizItems.length,
                backgroundColor: Colors.grey[300],
                minHeight: 8,
              ),
              const SizedBox(height: 32),

              // Question card
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question
                          Text(
                            _currentItem.question,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Answer input
                          if (!_showAnswer) ...[
                            TextField(
                              controller: _answerController,
                              decoration: const InputDecoration(
                                labelText: 'Your answer',
                                border: OutlineInputBorder(),
                                hintText: 'Type your answer here...',
                              ),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                              onSubmitted: (_) => _showAnswerPressed(),
                            ),
                          ],

                          // Show correct answer
                          if (_showAnswer) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Correct Answer:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _currentItem.answer,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_userAnswer != null && _userAnswer!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Your answer: $_userAnswer',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Action buttons
              const SizedBox(height: 20),
              if (!_showAnswer)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _showAnswerPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Show Answer'),
                  ),
                ),

              if (_showAnswer) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _submitAnswer(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Incorrect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _submitAnswer(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Correct'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
