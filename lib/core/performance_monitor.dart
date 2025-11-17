import 'package:flutter/foundation.dart';

/// Simple performance monitoring utility
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _durations = {};

  /// Start timing an operation
  static void start(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  /// End timing and log result
  static void end(String operationName) {
    final endTime = DateTime.now();
    final startTime = _startTimes[operationName];

    if (startTime != null) {
      final duration = endTime.difference(startTime).inMilliseconds;

      // Store duration
      _durations.putIfAbsent(operationName, () => []);
      _durations[operationName]!.add(duration);

      // Log if slow
      if (duration > 1000) {
        debugPrint('⚠️ SLOW: $operationName took ${duration}ms');
      }

      // Keep only last 10 measurements
      if (_durations[operationName]!.length > 10) {
        _durations[operationName]!.removeAt(0);
      }

      _startTimes.remove(operationName);
    }
  }

  /// Get average duration for an operation
  static double? getAverage(String operationName) {
    final durations = _durations[operationName];
    if (durations == null || durations.isEmpty) return null;

    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  /// Get all stats
  static Map<String, double> getAllAverages() {
    final result = <String, double>{};

    for (var entry in _durations.entries) {
      if (entry.value.isNotEmpty) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        result[entry.key] = avg;
      }
    }

    return result;
  }

  /// Clear all data
  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }

  /// Print current stats
  static void printStats() {
    debugPrint('=== Performance Stats ===');
    final averages = getAllAverages();

    if (averages.isEmpty) {
      debugPrint('No data collected yet');
      return;
    }

    for (var entry in averages.entries) {
      debugPrint('${entry.key}: ${entry.value.toStringAsFixed(1)}ms avg');
    }
    debugPrint('========================');
  }
}
