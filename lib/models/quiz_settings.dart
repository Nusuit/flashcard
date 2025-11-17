import 'package:flutter/material.dart';

/// Quiz popup settings
class QuizSettings {
  final bool enabled;
  final Duration interval;
  final QuizPopupPosition position;
  final bool onlyWhenIdle;
  final int idleMinutes;

  QuizSettings({
    this.enabled = true,
    this.interval = const Duration(minutes: 30),
    this.position = QuizPopupPosition.topRight,
    this.onlyWhenIdle = false,
    this.idleMinutes = 5,
  });

  QuizSettings copyWith({
    bool? enabled,
    Duration? interval,
    QuizPopupPosition? position,
    bool? onlyWhenIdle,
    int? idleMinutes,
  }) {
    return QuizSettings(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      position: position ?? this.position,
      onlyWhenIdle: onlyWhenIdle ?? this.onlyWhenIdle,
      idleMinutes: idleMinutes ?? this.idleMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled ? 1 : 0,
      'interval_minutes': interval.inMinutes,
      'position': position.index,
      'only_when_idle': onlyWhenIdle ? 1 : 0,
      'idle_minutes': idleMinutes,
    };
  }

  factory QuizSettings.fromMap(Map<String, dynamic> map) {
    return QuizSettings(
      enabled: map['enabled'] == 1,
      interval: Duration(minutes: map['interval_minutes'] ?? 30),
      position: QuizPopupPosition.values[map['position'] ?? 0],
      onlyWhenIdle: map['only_when_idle'] == 1,
      idleMinutes: map['idle_minutes'] ?? 5,
    );
  }
}

enum QuizPopupPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

extension QuizPopupPositionExt on QuizPopupPosition {
  Alignment get alignment {
    switch (this) {
      case QuizPopupPosition.topLeft:
        return Alignment.topLeft;
      case QuizPopupPosition.topRight:
        return Alignment.topRight;
      case QuizPopupPosition.bottomLeft:
        return Alignment.bottomLeft;
      case QuizPopupPosition.bottomRight:
        return Alignment.bottomRight;
      case QuizPopupPosition.center:
        return Alignment.center;
    }
  }

  String get displayName {
    switch (this) {
      case QuizPopupPosition.topLeft:
        return 'Góc trên trái';
      case QuizPopupPosition.topRight:
        return 'Góc trên phải';
      case QuizPopupPosition.bottomLeft:
        return 'Góc dưới trái';
      case QuizPopupPosition.bottomRight:
        return 'Góc dưới phải';
      case QuizPopupPosition.center:
        return 'Giữa màn hình';
    }
  }
}
