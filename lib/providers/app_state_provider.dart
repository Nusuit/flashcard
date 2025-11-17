import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/vocabulary.dart';
import '../models/knowledge.dart';
import '../core/storage_manager.dart';
import '../core/quiz_scheduler.dart';
import '../core/quiz_queue_builder.dart';

/// Global app state management using Provider
class AppStateProvider extends ChangeNotifier {
  final StorageManager _storage = StorageManager();

  AppSettings _settings = AppSettings();
  Map<String, int> _counts = {};
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;

  // Pagination state for knowledge list
  List<Knowledge> _knowledgeListItems = [];
  bool _isLoadingKnowledge = false;
  bool _hasMoreKnowledge = true;
  static const int _knowledgePageSize = 20;

  AppSettings get settings => _settings;
  Map<String, int> get counts => _counts;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  StorageManager get storage => _storage;

  // Getters for knowledge pagination
  List<Knowledge> get knowledgeListItems => _knowledgeListItems;
  bool get isLoadingKnowledge => _isLoadingKnowledge;
  bool get hasMoreKnowledge => _hasMoreKnowledge;

  AppStateProvider() {
    _loadInitialData();
  }

  /// Load initial data on app start
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _storage.loadSettings();
      await refreshDashboard();
      await loadKnowledgeList(isInitial: true); // Load first page
    } catch (e) {
      print('Error loading initial data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh dashboard data (counts and statistics)
  Future<void> refreshDashboard() async {
    try {
      _counts = await _storage.getCounts();
      _statistics = await _storage.getStatistics();
      notifyListeners();
    } catch (e) {
      print('Error refreshing dashboard: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _storage.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    final newSettings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await updateSettings(newSettings);
  }

  /// Add vocabulary
  Future<void> addVocabulary(Vocabulary vocab) async {
    try {
      await _storage.insertVocabulary(vocab);
      await refreshDashboard();
    } catch (e) {
      print('Error adding vocabulary: $e');
      rethrow;
    }
  }

  /// Add knowledge
  Future<void> addKnowledge(Knowledge knowledge) async {
    try {
      final id = await _storage.insertKnowledge(knowledge);
      QuizScheduler().clearCache(); // Clear cache when data changes

      // Build quiz queue in background (non-blocking)
      final knowledgeWithId = knowledge.copyWith(id: id);
      QuizQueueBuilder().buildQueueForKnowledge(knowledgeWithId);

      await refreshDashboard();

      // Reset knowledge list to reload from beginning
      _knowledgeListItems.clear();
      _hasMoreKnowledge = true;
      await loadKnowledgeList(isInitial: true);
    } catch (e) {
      print('Error adding knowledge: $e');
      rethrow;
    }
  }

  /// Load knowledge list with pagination
  ///
  /// API Test:
  /// ```dart
  /// // Initial load
  /// await appState.loadKnowledgeList(isInitial: true);
  /// // Load more
  /// await appState.loadKnowledgeList();
  /// ```
  Future<void> loadKnowledgeList({bool isInitial = false}) async {
    if (_isLoadingKnowledge || (!_hasMoreKnowledge && !isInitial)) return;

    _isLoadingKnowledge = true;
    if (isInitial) {
      _knowledgeListItems.clear();
      _hasMoreKnowledge = true;
    }
    notifyListeners();

    try {
      final offset = isInitial ? 0 : _knowledgeListItems.length;
      final newItems = await _storage.getAllKnowledge(
        limit: _knowledgePageSize,
        offset: offset,
      );

      if (newItems.length < _knowledgePageSize) {
        _hasMoreKnowledge = false;
      }

      _knowledgeListItems.addAll(newItems);
    } catch (e) {
      print('Error loading knowledge list: $e');
    }

    _isLoadingKnowledge = false;
    notifyListeners();
  }

  /// Get knowledge list (deprecated, use knowledgeListItems getter)
  @Deprecated('Use knowledgeListItems getter and loadKnowledgeList() instead')
  Future<List<Knowledge>> getKnowledgeList() async {
    try {
      return await _storage.getAllKnowledge();
    } catch (e) {
      print('Error getting knowledge list: $e');
      return [];
    }
  }

  /// Get total items count
  int get totalItems =>
      (_counts['vocabulary'] ?? 0) +
      (_counts['knowledge'] ?? 0) +
      (_counts['questions'] ?? 0);
}
