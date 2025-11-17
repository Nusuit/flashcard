import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_state_provider.dart';
import '../core/storage_manager.dart';

/// Study Session Screen - Continuous quiz mode
class StudySessionScreen extends StatefulWidget {
  final int? knowledgeId;
  final int questionCount;

  const StudySessionScreen({
    super.key,
    this.knowledgeId,
    this.questionCount = 10,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final StorageManager _storage = StorageManager();
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);

    // TODO: Get questions using SpacedRepetitionEngine
    // For now, get random questions
    final questions = widget.knowledgeId != null
        ? await _storage.getQuestionsByKnowledgeId(widget.knowledgeId!)
        : await _storage.getRandomQuestions(limit: widget.questionCount);

    if (questions.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có câu hỏi nào')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = false);

    // Reset session stats
    context.read<QuizStateProvider>().resetSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Study Session ${_currentIndex + 1}/${widget.questionCount}'),
        actions: [
          Consumer<QuizStateProvider>(
            builder: (context, quiz, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${quiz.sessionCorrectCount}/${quiz.sessionQuestionsCount}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _currentIndex / widget.questionCount,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          // Quiz content
          Expanded(
            child: Center(
              child: Text('Quiz UI will be here\nCurrent: $_currentIndex'),
            ),
          ),
        ],
      ),
    );
  }
}
