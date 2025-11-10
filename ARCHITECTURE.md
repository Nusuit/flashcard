# ARCHITECTURE.md

## 🏗️ Knop System Architecture

This document provides a comprehensive overview of the Knop flashcard application's architecture, design patterns, and implementation details.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Data Flow](#data-flow)
4. [Component Design](#component-design)
5. [State Management](#state-management)
6. [Background Processing](#background-processing)
7. [LLM Integration](#llm-integration)
8. [Security & Privacy](#security--privacy)

---

## System Overview

Knop is built using Flutter for cross-platform support (mobile and desktop) with a focus on:

- **Local-first architecture**: All data stored on-device
- **Privacy by design**: No cloud services required
- **Modular structure**: Easy to extend and maintain
- **Offline capability**: Works without internet (except LLM features)

### Technology Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Database**: SQLite (via sqflite)
- **State Management**: Provider
- **Notifications**: flutter_local_notifications
- **Background Tasks**: workmanager
- **LLM Integration**: Ollama (HTTP API)

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Home Screen  │  │ Quiz Screen  │  │ Settings     │      │
│  │ Vocabulary   │  │ Knowledge    │  │ Dashboard    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                   STATE MANAGEMENT LAYER                     │
│  ┌──────────────────────────────────────────────┐           │
│  │         AppStateProvider (Provider)          │           │
│  │  - Settings Management                       │           │
│  │  - Dashboard Statistics                      │           │
│  │  - UI State Synchronization                  │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Flashcard   │  │   Reminder   │  │     LLM      │      │
│  │   Engine     │  │   Engine     │  │  Generator   │      │
│  │              │  │              │  │              │      │
│  │ - Quiz Gen   │  │ - Scheduling │  │ - Question   │      │
│  │ - Scoring    │  │ - Notif Mgmt │  │   Creation   │      │
│  │ - Algorithms │  │ - Background │  │ - Ollama API │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                       DATA ACCESS LAYER                      │
│  ┌──────────────────────────────────────────────┐           │
│  │           StorageManager (SQLite)            │           │
│  │  - CRUD Operations                           │           │
│  │  - Query Optimization                        │           │
│  │  - Transaction Management                    │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                            │
│  ┌──────────────────────────────────────────────┐           │
│  │                SQLite Database                │           │
│  │  - vocabulary                                 │           │
│  │  - knowledge                                  │           │
│  │  - quiz_questions                             │           │
│  │  - quiz_history                               │           │
│  │  - settings                                   │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. Quiz Generation Flow

```
User Triggers Quiz
    ↓
FlashcardEngine.generateQuizSession()
    ↓
Reads AppSettings from Provider
    ↓
Queries StorageManager
    ├→ getRandomVocabulary() (if language mode)
    └→ getRandomQuestions() (if knowledge mode)
    ↓
Applies selection algorithm (prioritize weak items)
    ↓
Creates QuizItem objects
    ↓
Shuffles and returns list
    ↓
QuizScreen displays questions
    ↓
User answers
    ↓
FlashcardEngine.recordAnswer()
    ├→ Saves to quiz_history
    └→ Updates item statistics (times_shown, times_correct)
    ↓
Updates dashboard statistics
```

### 2. LLM Question Generation Flow

```
User creates Knowledge note
    ↓
Saved to database via StorageManager
    ↓
User navigates to KnowledgeDetailScreen
    ↓
User clicks "Generate Questions with AI"
    ↓
LLMQuestionGenerator.generateQuestions()
    ↓
Checks Ollama availability
    ↓
Builds prompt with user's notes
    ↓
HTTP POST to Ollama API (localhost:11434)
    ↓
Ollama processes with selected model (phi3/mistral)
    ↓
Returns JSON with questions
    ↓
Parse and validate response
    ↓
StorageManager.insertQuizQuestions()
    ↓
Questions available for quizzes
```

### 3. Reminder Flow

```
App initializes
    ↓
ReminderEngine.initialize()
    ↓
Loads AppSettings
    ↓
ReminderEngine.scheduleReminders()
    ↓
WorkManager registers periodic task
    ↓
[Time passes...]
    ↓
Background callback triggered
    ↓
Check if within active hours
    ↓
If yes: Display notification
    ↓
User taps notification
    ↓
App opens to QuizScreen
    ↓
Quiz session begins
```

---

## Component Design

### Core Components

#### 1. FlashcardEngine

**Responsibility**: Quiz generation and answer validation

**Key Methods**:

```dart
Future<List<QuizItem>> generateQuizSession(AppSettings)
Future<void> recordAnswer(QuizItem, bool wasCorrect)
bool checkAnswer(String userAnswer, String correctAnswer)
double getSimilarity(String, String)
```

**Design Patterns**:

- Strategy Pattern: Different quiz modes (word→meaning, meaning→word, etc.)
- Factory Pattern: Creating QuizItems from different sources

#### 2. StorageManager

**Responsibility**: Database operations and data persistence

**Key Methods**:

```dart
Future<int> insertVocabulary(Vocabulary)
Future<List<Vocabulary>> getRandomVocabulary({params})
Future<Map<String, dynamic>> getStatistics()
Future<AppSettings> loadSettings()
```

**Design Patterns**:

- Singleton Pattern: Single database instance
- Repository Pattern: Abstraction over data source
- DAO Pattern: Separate methods for each entity type

#### 3. ReminderEngine

**Responsibility**: Background notifications and scheduling

**Key Methods**:

```dart
Future<void> initialize()
Future<void> scheduleReminders(AppSettings)
Future<void> showQuizNotification()
Future<bool> requestPermissions()
```

**Design Patterns**:

- Singleton Pattern: Single notification manager
- Observer Pattern: Notification callbacks

#### 4. LLMQuestionGenerator

**Responsibility**: AI-powered question generation

**Key Methods**:

```dart
Future<List<QuizQuestion>> generateQuestions(Knowledge)
Future<bool> isAvailable()
Future<List<String>> getAvailableModels()
```

**Design Patterns**:

- Adapter Pattern: Wraps Ollama HTTP API
- Builder Pattern: Constructs prompts

---

## State Management

### Provider Pattern Implementation

**AppStateProvider** is the central state management class:

```dart
class AppStateProvider extends ChangeNotifier {
  AppSettings _settings;
  Map<String, int> _counts;
  Map<String, dynamic> _statistics;

  // Methods notify listeners on state changes
  Future<void> updateSettings(AppSettings newSettings) async {
    await _storage.saveSettings(newSettings);
    _settings = newSettings;
    notifyListeners(); // Triggers UI rebuild
  }
}
```

**Benefits**:

- Simple and built into Flutter
- Easy to test
- Minimal boilerplate
- Efficient UI updates

**State Flow**:

```
User Action → Provider Method → Database Update → notifyListeners() → UI Rebuilds
```

---

## Background Processing

### Notification System

**Android Implementation**:

- Uses WorkManager for periodic tasks
- Creates notification channel with high importance
- Respects system battery optimizations

**iOS Implementation**:

- Uses flutter_local_notifications
- Requests permissions at app start
- Schedules local notifications

**Configuration**:

```dart
await Workmanager().registerPeriodicTask(
  'knopQuizReminder',
  'knopQuizReminder',
  frequency: Duration(hours: settings.reminderIntervalHours),
  constraints: Constraints(
    networkType: NetworkType.not_required,
  ),
);
```

---

## LLM Integration

### Ollama Architecture

```
┌──────────────┐         HTTP          ┌──────────────┐
│   Knop App   │ ─────────────────────→ │   Ollama     │
│              │    POST /api/generate  │   Server     │
│ LLMQuestion  │                        │ (localhost)  │
│  Generator   │ ←───────────────────── │              │
└──────────────┘    JSON Response       └──────────────┘
                                               ↓
                                        ┌──────────────┐
                                        │  AI Models   │
                                        │  - phi3      │
                                        │  - mistral   │
                                        │  - llama2    │
                                        └──────────────┘
```

### Prompt Engineering

Knop uses structured prompts to ensure quality output:

1. **Clear instructions**: Specify format and requirements
2. **Examples**: Show desired output structure
3. **Constraints**: Limit question types and length
4. **JSON output**: Enforce structured responses

---

## Security & Privacy

### Data Privacy Principles

1. **Local Storage**: All data stays on device
2. **No Analytics**: No tracking or telemetry
3. **No Cloud Sync**: Optional feature for future
4. **Encrypted at Rest**: SQLite database (OS-level)

### LLM Privacy

- Ollama runs **locally** on user's machine
- No data sent to external servers
- User controls which model to use
- Can function completely offline (without LLM)

---

## Performance Considerations

### Database Optimization

- **Indexes**: Created on frequently queried columns
- **Batch Operations**: Use transactions for multiple inserts
- **Lazy Loading**: Only load needed data
- **Query Limits**: Prevent loading entire database

### Memory Management

- **Dispose Controllers**: Properly dispose TextEditingControllers
- **Image Caching**: Future feature for vocabulary images
- **Pagination**: Implement for large lists

---

## Testing Strategy

### Unit Tests

- Model serialization/deserialization
- Quiz scoring algorithms
- Answer similarity calculations

### Integration Tests

- Database operations
- State management flows
- LLM API integration

### Widget Tests

- Screen rendering
- User interactions
- Navigation flows

---

## Extensibility

### Adding New Features

The modular architecture allows easy extensions:

1. **New Quiz Types**: Extend `VocabularyQuizMode` enum
2. **New Data Sources**: Implement additional `StorageManager` methods
3. **New AI Providers**: Create adapter for different LLM APIs
4. **Cloud Sync**: Add sync layer above `StorageManager`

### Plugin Points

- Custom quiz algorithms
- Alternative storage backends
- Additional notification channels
- Theme customization

---

## Deployment

### Platform-Specific Builds

**Android**:

```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS**:

```bash
flutter build ios --release
```

**Desktop**:

```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

---

## Future Architecture Enhancements

1. **Microservices**: Split into smaller services
2. **Event Sourcing**: Track all state changes
3. **CQRS**: Separate read/write operations
4. **GraphQL**: For future API layer
5. **WebAssembly**: Web version support

---

**Last Updated**: November 2025  
**Version**: 1.0.0
