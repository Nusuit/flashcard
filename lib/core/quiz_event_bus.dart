import 'dart:async';
import 'package:flutter/material.dart';

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
    debugPrint(
        '🔥 EVENT BUS FIRE: ${event.type}, hasListeners: ${_controller.hasListener}, isClosed: ${_controller.isClosed}');
    if (!_controller.isClosed) {
      _controller.add(event);
      debugPrint('✓ Event added to stream');
    } else {
      debugPrint('❌ Controller is closed, cannot fire event');
    }
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
