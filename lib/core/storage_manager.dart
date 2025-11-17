import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vocabulary.dart';
import '../models/knowledge.dart';
import '../models/quiz_question.dart';
import '../models/quiz_history.dart';
import '../models/app_settings.dart';

/// Manages all local SQLite database operations
class StorageManager {
  static final StorageManager _instance = StorageManager._internal();
  static Database? _database;

  factory StorageManager() => _instance;

  StorageManager._internal();

  /// Get database instance, create if doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'knop_flashcard.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to knowledge table
      await db.execute('ALTER TABLE knowledge ADD COLUMN description TEXT DEFAULT ""');
      await db.execute('ALTER TABLE knowledge ADD COLUMN reminder_time TEXT');
      await db.execute('ALTER TABLE knowledge ADD COLUMN pdf_files TEXT DEFAULT ""');
      await db.execute('ALTER TABLE knowledge ADD COLUMN last_modified TEXT');
    }
    if (oldVersion < 3) {
      // Add mode column to knowledge table
      await db.execute('ALTER TABLE knowledge ADD COLUMN mode TEXT DEFAULT "normal"');
    }
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    // Vocabulary table
    await db.execute('''
      CREATE TABLE vocabulary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL,
        word TEXT NOT NULL,
        pinyin TEXT,
        meaning_vi TEXT NOT NULL,
        example_sentence TEXT,
        difficulty INTEGER DEFAULT 1,
        times_correct INTEGER DEFAULT 0,
        times_shown INTEGER DEFAULT 0,
        last_shown TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Knowledge table
    await db.execute('''
      CREATE TABLE knowledge (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        content TEXT NOT NULL,
        description TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        reminder_time TEXT,
        pdf_files TEXT DEFAULT '',
        last_modified TEXT,
        mode TEXT DEFAULT 'normal'
      )
    ''');

    // Quiz questions table
    await db.execute('''
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        knowledge_id INTEGER,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        question_type TEXT DEFAULT 'open',
        options TEXT,
        times_correct INTEGER DEFAULT 0,
        times_shown INTEGER DEFAULT 0,
        last_shown TEXT,
        FOREIGN KEY (knowledge_id) REFERENCES knowledge(id) ON DELETE CASCADE
      )
    ''');

    // Quiz history table
    await db.execute('''
      CREATE TABLE quiz_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        was_correct INTEGER NOT NULL,
        answered_at TEXT NOT NULL
      )
    ''');

    // Settings table (key-value store)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_vocabulary_language ON vocabulary(language)');
    await db.execute('CREATE INDEX idx_vocabulary_last_shown ON vocabulary(last_shown)');
    await db.execute('CREATE INDEX idx_quiz_questions_knowledge_id ON quiz_questions(knowledge_id)');
    await db.execute('CREATE INDEX idx_quiz_history_answered_at ON quiz_history(answered_at)');
  }

  // ==================== VOCABULARY OPERATIONS ====================

  /// Insert a new vocabulary item
  Future<int> insertVocabulary(Vocabulary vocab) async {
    final db = await database;
    return await db.insert('vocabulary', vocab.toMap());
  }

  /// Get all vocabulary items
  Future<List<Vocabulary>> getAllVocabulary({String? language}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (language != null) {
      maps = await db.query(
        'vocabulary',
        where: 'language = ?',
        whereArgs: [language],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('vocabulary', orderBy: 'created_at DESC');
    }

    return List.generate(maps.length, (i) => Vocabulary.fromMap(maps[i]));
  }

  /// Get vocabulary by ID
  Future<Vocabulary?> getVocabularyById(int id) async {
    final db = await database;
    final maps = await db.query(
      'vocabulary',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Vocabulary.fromMap(maps.first);
  }

  /// Update vocabulary item
  Future<int> updateVocabulary(Vocabulary vocab) async {
    final db = await database;
    return await db.update(
      'vocabulary',
      vocab.toMap(),
      where: 'id = ?',
      whereArgs: [vocab.id],
    );
  }

  /// Delete vocabulary item
  Future<int> deleteVocabulary(int id) async {
    final db = await database;
    return await db.delete(
      'vocabulary',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get random vocabulary items for quiz
  Future<List<Vocabulary>> getRandomVocabulary({
    int limit = 5,
    String? language,
    bool prioritizeWeak = true,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM vocabulary';
    List<dynamic> args = [];

    if (language != null) {
      query += ' WHERE language = ?';
      args.add(language);
    }

    if (prioritizeWeak) {
      // Prioritize items with low success rate or never shown
      query += language != null ? ' AND' : ' WHERE';
      query += ' (times_shown = 0 OR (times_correct * 1.0 / times_shown) < 0.6)';
    }

    query += ' ORDER BY RANDOM() LIMIT ?';
    args.add(limit);

    final maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) => Vocabulary.fromMap(maps[i]));
  }

  // ==================== KNOWLEDGE OPERATIONS ====================

  /// Insert a new knowledge item
  Future<int> insertKnowledge(Knowledge knowledge) async {
    final db = await database;
    return await db.insert('knowledge', knowledge.toMap());
  }

  /// Get all knowledge items
  Future<List<Knowledge>> getAllKnowledge({String? topic}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (topic != null) {
      maps = await db.query(
        'knowledge',
        where: 'topic = ?',
        whereArgs: [topic],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('knowledge', orderBy: 'created_at DESC');
    }

    return List.generate(maps.length, (i) => Knowledge.fromMap(maps[i]));
  }

  /// Get knowledge by ID
  Future<Knowledge?> getKnowledgeById(int id) async {
    final db = await database;
    final maps = await db.query(
      'knowledge',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Knowledge.fromMap(maps.first);
  }

  /// Update knowledge item
  Future<int> updateKnowledge(Knowledge knowledge) async {
    final db = await database;
    return await db.update(
      'knowledge',
      knowledge.toMap(),
      where: 'id = ?',
      whereArgs: [knowledge.id],
    );
  }

  /// Delete knowledge item and associated questions
  Future<int> deleteKnowledge(int id) async {
    final db = await database;
    // Questions will be deleted automatically due to CASCADE
    return await db.delete(
      'knowledge',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== QUIZ QUESTION OPERATIONS ====================

  /// Insert a new quiz question
  Future<int> insertQuizQuestion(QuizQuestion question) async {
    final db = await database;
    return await db.insert('quiz_questions', question.toMap());
  }

  /// Insert multiple quiz questions
  Future<void> insertQuizQuestions(List<QuizQuestion> questions) async {
    final db = await database;
    final batch = db.batch();
    for (var question in questions) {
      batch.insert('quiz_questions', question.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Get all quiz questions for a knowledge item
  Future<List<QuizQuestion>> getQuestionsByKnowledgeId(int knowledgeId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_questions',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
    );

    return List.generate(maps.length, (i) => QuizQuestion.fromMap(maps[i]));
  }

  /// Get random quiz questions
  Future<List<QuizQuestion>> getRandomQuestions({
    int limit = 5,
    bool prioritizeWeak = true,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM quiz_questions';

    if (prioritizeWeak) {
      query += ' WHERE (times_shown = 0 OR (times_correct * 1.0 / times_shown) < 0.6)';
    }

    query += ' ORDER BY RANDOM() LIMIT ?';

    final maps = await db.rawQuery(query, [limit]);
    return List.generate(maps.length, (i) => QuizQuestion.fromMap(maps[i]));
  }

  /// Update quiz question
  Future<int> updateQuizQuestion(QuizQuestion question) async {
    final db = await database;
    return await db.update(
      'quiz_questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  /// Delete quiz question
  Future<int> deleteQuizQuestion(int id) async {
    final db = await database;
    return await db.delete(
      'quiz_questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== QUIZ HISTORY OPERATIONS ====================

  /// Insert quiz history record
  Future<int> insertQuizHistory(QuizHistory history) async {
    final db = await database;
    return await db.insert('quiz_history', history.toMap());
  }

  /// Get recent quiz history
  Future<List<QuizHistory>> getRecentHistory({int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'quiz_history',
      orderBy: 'answered_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => QuizHistory.fromMap(maps[i]));
  }

  /// Get statistics for a date range
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN was_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM quiz_history
      WHERE answered_at >= ? AND answered_at <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final total = (result.first['total'] as int?) ?? 0;
    final correct = (result.first['correct'] as int?) ?? 0;

    return {
      'total': total,
      'correct': correct,
      'accuracy': total > 0 ? (correct / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  // ==================== SETTINGS OPERATIONS ====================

  /// Save settings
  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    final settingsMap = settings.toMap();

    final batch = db.batch();
    for (var entry in settingsMap.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Load settings
  Future<AppSettings> loadSettings() async {
    final db = await database;
    final maps = await db.query('settings');

    if (maps.isEmpty) {
      // Return default settings
      return AppSettings();
    }

    final settingsMap = <String, dynamic>{};
    for (var map in maps) {
      final key = map['key'] as String;
      final value = map['value'] as String;

      // Parse value based on key
      if (key.contains('hours') || key.contains('per_session')) {
        settingsMap[key] = int.tryParse(value) ?? 0;
      } else if (key == 'is_dark_mode') {
        settingsMap[key] = int.tryParse(value) ?? 0;
      } else {
        settingsMap[key] = value;
      }
    }

    return AppSettings.fromMap(settingsMap);
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get total counts for dashboard
  Future<Map<String, int>> getCounts() async {
    final db = await database;
    
    final vocabCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vocabulary'),
    ) ?? 0;
    
    final knowledgeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM knowledge'),
    ) ?? 0;
    
    final questionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quiz_questions'),
    ) ?? 0;

    return {
      'vocabulary': vocabCount,
      'knowledge': knowledgeCount,
      'questions': questionsCount,
    };
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('vocabulary');
    await db.delete('knowledge');
    await db.delete('quiz_questions');
    await db.delete('quiz_history');
    await db.delete('settings');
  }
}
