import 'dart:async';

/// Event types for quiz system
enum QuizEventType {
  quizReady,
  quizCompleted,
  quizClosed,
  quizPaused,
  quizResumed,
}

/// Quiz event data
class QuizEvent {
  final QuizEventType type;
  final Map<String, dynamic>? data;

  QuizEvent(this.type, {this.data});
}

/// Simple event bus for quiz system
class QuizEventBus {
  static final QuizEventBus _instance = QuizEventBus._internal();
  factory QuizEventBus() => _instance;
  QuizEventBus._internal();

  final _controller = StreamController<QuizEvent>.broadcast(
    onCancel: () {
      // Clean up when no listeners
    },
  );

  Stream<QuizEvent> get stream => _controller.stream;

  void fire(QuizEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
