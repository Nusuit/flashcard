import 'package:flutter/foundation.dart';
import 'storage_manager.dart';
import 'quiz_queue_builder.dart';

/// One-time migration to build quiz queue for existing knowledge
/// Run this after upgrading to database version 4
class QueueMigration {
  final StorageManager _storage = StorageManager();
  final QuizQueueBuilder _queueBuilder = QuizQueueBuilder();

  /// Check if migration is needed and execute
  ///
  /// API Test:
  /// ```dart
  /// final migration = QueueMigration();
  /// final didMigrate = await migration.runMigrationIfNeeded();
  /// print('Migration ran: $didMigrate');
  /// // Check console logs:
  /// // "Building queue for: [knowledge topic]"
  /// // "Queue migration complete: X built, Y skipped"
  /// ```
  ///
  /// Usage:
  /// - Called automatically in main.dart on app startup
  /// - Checks each knowledge for existing queue
  /// - Builds queue if missing (background job)
  /// - Idempotent: safe to run multiple times
  ///
  /// Database Check:
  /// ```sql
  /// -- Before: SELECT COUNT(*) FROM quiz_queue; → 0
  /// -- After:  SELECT COUNT(*) FROM quiz_queue; → 50+
  /// ```
  ///
  /// @returns Future<bool> true if migration ran, false if not needed
  Future<bool> runMigrationIfNeeded() async {
    try {
      // Check if we have any knowledge without queue items
      final allKnowledge = await _storage.getAllKnowledge();

      if (allKnowledge.isEmpty) {
        debugPrint('No knowledge found, migration not needed');
        return false;
      }

      int migratedCount = 0;
      int skippedCount = 0;

      for (final knowledge in allKnowledge) {
        // Check if queue already exists for this knowledge
        final hasQueue = await _storage.hasQuizQueue(knowledge.id!);

        if (!hasQueue) {
          // Build queue in background (non-blocking)
          debugPrint('Building queue for: ${knowledge.topic}');
          await _queueBuilder.buildQueueForKnowledge(knowledge);
          migratedCount++;
        } else {
          skippedCount++;
        }
      }

      debugPrint(
          'Queue migration complete: $migratedCount built, $skippedCount skipped');
      return migratedCount > 0;
    } catch (e) {
      debugPrint('Queue migration error: $e');
      return false;
    }
  }

  /// Force rebuild all queues (for troubleshooting)
  Future<void> rebuildAllQueues() async {
    try {
      final allKnowledge = await _storage.getAllKnowledge();

      for (final knowledge in allKnowledge) {
        debugPrint('Rebuilding queue for: ${knowledge.topic}');
        await _queueBuilder.rebuildQueue(knowledge.id!);
      }

      debugPrint('Rebuilt ${allKnowledge.length} queues');
    } catch (e) {
      debugPrint('Rebuild all queues error: $e');
    }
  }

  /// Get migration status for UI display
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final allKnowledge = await _storage.getAllKnowledge();
      int withQueue = 0;
      int withoutQueue = 0;

      for (final knowledge in allKnowledge) {
        final hasQueue = await _storage.hasQuizQueue(knowledge.id!);
        if (hasQueue) {
          withQueue++;
        } else {
          withoutQueue++;
        }
      }

      return {
        'total': allKnowledge.length,
        'withQueue': withQueue,
        'withoutQueue': withoutQueue,
        'migrationNeeded': withoutQueue > 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'withQueue': 0,
        'withoutQueue': 0,
        'migrationNeeded': false,
        'error': e.toString(),
      };
    }
  }
}
