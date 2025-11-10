# API Documentation

## Storage Manager API

### Vocabulary Operations

#### `insertVocabulary(Vocabulary vocab)`

Inserts a new vocabulary item into the database.

**Parameters**:

- `vocab`: Vocabulary object to insert

**Returns**: `Future<int>` - The ID of the inserted item

**Example**:

```dart
final vocab = Vocabulary(
  language: 'en',
  word: 'apple',
  meaningVi: 'quả táo',
);
final id = await storage.insertVocabulary(vocab);
```

#### `getRandomVocabulary({int limit, String? language, bool prioritizeWeak})`

Retrieves random vocabulary items, optionally prioritizing items with low success rates.

**Parameters**:

- `limit`: Maximum number of items (default: 5)
- `language`: Filter by language ('en' or 'cn')
- `prioritizeWeak`: Prioritize items needing practice (default: true)

**Returns**: `Future<List<Vocabulary>>`

---

## Flashcard Engine API

### Quiz Generation

#### `generateQuizSession(AppSettings settings)`

Generates a quiz session based on user settings.

**Parameters**:

- `settings`: App settings containing quiz mode, question count, etc.

**Returns**: `Future<List<QuizItem>>`

**Algorithm**:

1. Determine question distribution based on `quizMode`
2. Fetch random vocabulary/knowledge items
3. Apply weak-item prioritization
4. Shuffle results
5. Create QuizItem objects with questions/answers

---

## LLM Question Generator API

### Question Generation

#### `generateQuestions({required Knowledge knowledge, int numberOfQuestions})`

Generates quiz questions from knowledge notes using LLM.

**Parameters**:

- `knowledge`: Knowledge object containing study notes
- `numberOfQuestions`: Number of questions to generate (default: 3)

**Returns**: `Future<List<QuizQuestion>>`

**Throws**: `Exception` if Ollama is unavailable or parsing fails

**Example**:

```dart
final generator = LLMQuestionGenerator();
final questions = await generator.generateQuestions(
  knowledge: myKnowledge,
  numberOfQuestions: 5,
);
```

---

## Reminder Engine API

### Notification Management

#### `scheduleReminders(AppSettings settings)`

Schedules periodic quiz reminders based on settings.

**Parameters**:

- `settings`: Settings containing interval and active hours

**Example**:

```dart
final engine = ReminderEngine();
await engine.scheduleReminders(appSettings);
```

#### `showQuizNotification({String title, String body})`

Shows an immediate notification (for testing or manual triggers).

**Parameters**:

- `title`: Notification title (default: '🎴 Time for a Quiz!')
- `body`: Notification body (default: 'Ready to practice your flashcards?')

---

## Data Models

### Vocabulary Model

```dart
class Vocabulary {
  final int? id;
  final String language;      // 'en' or 'cn'
  final String word;
  final String? pinyin;       // Chinese only
  final String meaningVi;
  final String? exampleSentence;
  final int difficulty;       // 1-5
  final int timesCorrect;
  final int timesShown;
  final DateTime? lastShown;
  final DateTime createdAt;
}
```

### QuizQuestion Model

```dart
class QuizQuestion {
  final int? id;
  final int? knowledgeId;
  final String question;
  final String answer;
  final QuestionType questionType;
  final List<String>? options;
  final int timesCorrect;
  final int timesShown;
  final DateTime? lastShown;
}
```

### AppSettings Model

```dart
class AppSettings {
  final int reminderIntervalHours;
  final int activeHoursStart;
  final int activeHoursEnd;
  final QuizMode quizMode;
  final bool isDarkMode;
  final int questionsPerSession;
  final String ollamaModel;
  final String ollamaEndpoint;
}
```
