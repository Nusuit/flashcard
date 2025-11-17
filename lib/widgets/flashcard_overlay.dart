import 'dart:async';
import 'package:flutter/material.dart';
import '../models/knowledge.dart';
import '../models/vocabulary.dart';

enum OverlayMode {
  transparent,
  customBackground,
}

class FlashcardOverlay extends StatefulWidget {
  final dynamic item; // Knowledge or Vocabulary
  final VoidCallback? onDismiss;
  final OverlayMode mode;

  const FlashcardOverlay({
    super.key,
    required this.item,
    this.onDismiss,
    this.mode = OverlayMode.transparent,
  });

  @override
  State<FlashcardOverlay> createState() => _FlashcardOverlayState();
}

class _FlashcardOverlayState extends State<FlashcardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _answerController = TextEditingController();
  bool _showAnswer = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    // Hardcoded random evaluation as requested
    final isCorrect = DateTime.now().second % 2 == 0;
    setState(() {
      _showAnswer = true;
      _feedback = isCorrect ? 'Đúng rồi! 🎉' : 'Chưa đúng, cố gắng lần sau! 💪';
    });

    // Auto dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  String _getQuestionText() {
    if (widget.item is Knowledge) {
      final knowledge = widget.item as Knowledge;
      return knowledge.content;
    } else if (widget.item is Vocabulary) {
      final vocab = widget.item as Vocabulary;
      return 'Nghĩa của "${vocab.word}" là gì?';
    }
    return 'Câu hỏi mẫu';
  }

  String _getTitle() {
    if (widget.item is Knowledge) {
      final knowledge = widget.item as Knowledge;
      return knowledge.topic;
    } else if (widget.item is Vocabulary) {
      final vocab = widget.item as Vocabulary;
      return vocab.language;
    }
    return 'Flashcard';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      top: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            color: Colors.transparent,
            child: Container(
              width: screenSize.width * 0.3,
              constraints: const BoxConstraints(
                maxWidth: 400,
                minWidth: 300,
              ),
              decoration: BoxDecoration(
                gradient: widget.mode == OverlayMode.transparent
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF87CEEB).withOpacity(0.8),
                          const Color(0xFFB0E0E6).withOpacity(0.7),
                        ],
                      )
                    : null,
                color: widget.mode == OverlayMode.customBackground
                    ? Colors.white
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: widget.mode == OverlayMode.transparent
                      ? ColorFilter.mode(
                          Colors.white.withOpacity(0.1),
                          BlendMode.lighten,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.src,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF87CEEB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getTitle(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _dismiss,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quote/Question
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getQuestionText(),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Answer field
                        if (!_showAnswer)
                          TextField(
                            controller: _answerController,
                            decoration: InputDecoration(
                              hintText: 'Nhập câu trả lời...',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.95),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _checkAnswer(),
                          ),

                        // Feedback
                        if (_showAnswer && _feedback != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _feedback!.contains('Đúng')
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _feedback!.contains('Đúng')
                                    ? Colors.green
                                    : Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _feedback!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _feedback!.contains('Đúng')
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        if (!_showAnswer) const SizedBox(height: 12),

                        // Submit button
                        if (!_showAnswer)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _checkAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF87CEEB),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Kiểm Tra',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
