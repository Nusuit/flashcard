import 'package:flutter/material.dart';
import '../core/gemini_service.dart';
import '../models/quiz_question.dart';

/// Floating quiz popup widget that appears at scheduled times
class QuizPopup extends StatefulWidget {
  final QuizQuestion question;
  final String knowledgeContent;
  final VoidCallback onClose;
  final Function(bool isCorrect, int score) onAnswered;

  const QuizPopup({
    super.key,
    required this.question,
    required this.knowledgeContent,
    required this.onClose,
    required this.onAnswered,
  });

  @override
  State<QuizPopup> createState() => _QuizPopupState();
}

class _QuizPopupState extends State<QuizPopup>
    with SingleTickerProviderStateMixin {
  bool _isMinimized = false;
  bool _isAnswered = false;
  bool _isEvaluating = false;
  String? _selectedAnswer;
  String _userAnswer = '';
  Map<String, dynamic>? _evaluation;
  final TextEditingController _answerController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() async {
    if (_isAnswered) return;

    // For multiple choice
    if (widget.question.questionType == QuestionType.multipleChoice &&
        _selectedAnswer == null) {
      return;
    }

    // For text answers
    if (widget.question.questionType != QuestionType.multipleChoice &&
        _userAnswer.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAnswered = true;
      _isEvaluating = true;
    });

    // Use LLM to evaluate the answer
    final evaluation = await _geminiService.evaluateAnswer(
      question: widget.question.question,
      userAnswer: widget.question.questionType == QuestionType.multipleChoice
          ? _selectedAnswer!
          : _userAnswer,
      context: widget.knowledgeContent,
    );

    setState(() {
      _evaluation = evaluation;
      _isEvaluating = false;
    });

    widget.onAnswered(
      evaluation['isCorrect'] ?? false,
      evaluation['score'] ?? 0,
    );
  }

  void _askMoreQuestions() async {
    if (_evaluation == null) return;

    final feedback = _evaluation!['feedback'] as String? ?? '';

    // Open a dialog to ask follow-up questions
    showDialog(
      context: context,
      builder: (context) => _AskMoreDialog(
        initialContext: '''
Câu hỏi: ${widget.question.question}
Câu trả lời của tôi: ${widget.question.questionType == QuestionType.multipleChoice ? _selectedAnswer : _userAnswer}
Đánh giá: $feedback
''',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Positioned(
        top: 24,
        right: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isMinimized ? 300 : 400,
          constraints: BoxConstraints(
            maxHeight: _isMinimized ? 60 : 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isMinimized ? _buildMinimizedView() : _buildExpandedView(),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isMinimized = false),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quiz đang chờ...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quiz Time!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.minimize, color: Colors.white),
                onPressed: () => setState(() => _isMinimized = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  widget.question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Answer input
                if (!_isAnswered) ...[
                  if (widget.question.questionType ==
                      QuestionType.multipleChoice)
                    ..._buildMultipleChoiceOptions()
                  else
                    _buildTextAnswerInput(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Trả lời',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                // Evaluation result
                if (_isAnswered) ...[
                  if (_isEvaluating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_evaluation != null)
                    _buildEvaluationResult(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMultipleChoiceOptions() {
    final options = widget.question.options ?? [];
    return options.map((option) {
      final isSelected = _selectedAnswer == option;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() => _selectedAnswer = option),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : Colors.grey[50],
              border: Border.all(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? const Color(0xFF6366F1) : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF1F2937),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTextAnswerInput() {
    return TextField(
      controller: _answerController,
      onChanged: (value) => _userAnswer = value,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Nhập câu trả lời của bạn...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEvaluationResult() {
    final isCorrect = _evaluation!['isCorrect'] as bool? ?? false;
    final score = _evaluation!['score'] as int? ?? 0;
    final feedback = _evaluation!['feedback'] as String? ?? '';
    final suggestion = _evaluation!['suggestion'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info,
                color: isCorrect ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$score/100 điểm',
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Feedback
        if (feedback.isNotEmpty) ...[
          Text(
            'Nhận xét:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],

        // Suggestion
        if (suggestion.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Gợi ý:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Ask more button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _askMoreQuestions,
            icon: const Icon(Icons.help_outline),
            label: const Text('Hỏi thêm AI'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
      ],
    );
  }
}

// Dialog for asking follow-up questions
class _AskMoreDialog extends StatefulWidget {
  final String initialContext;

  const _AskMoreDialog({required this.initialContext});

  @override
  State<_AskMoreDialog> createState() => _AskMoreDialogState();
}

class _AskMoreDialogState extends State<_AskMoreDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<Map<String, String>> _conversation = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversation.add({
      'role': 'model',
      'content':
          'Tôi có thể giải thích thêm về câu trả lời này. Bạn muốn hỏi gì?',
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isLoading) return;

    setState(() {
      _conversation.add({'role': 'user', 'content': question});
      _isLoading = true;
      _questionController.clear();
    });

    final contextualQuestion = '${widget.initialContext}\n\nCâu hỏi: $question';
    final response = await _geminiService.chat(contextualQuestion);

    setState(() {
      _conversation.add({'role': 'model', 'content': response});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hỏi AI thêm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final msg = _conversation[index];
                  final isUser = msg['role'] == 'user';
                  return _buildMessageBubble(msg['content']!, isUser);
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Đang trả lời...',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6366F1)),
                    onPressed: _sendQuestion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.grey[800],
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
