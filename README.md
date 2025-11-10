# 🎴 Knop - Local AI Flashcard Reminder App

A privacy-first, fully offline flashcard application for language learning (English, Chinese, Vietnamese) and custom knowledge retention. Knop uses intelligent reminders and optional local LLM integration to help you master vocabulary and concepts through spaced repetition.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Data Flow](#-data-flow)
- [Database Schema](#-database-schema)
- [Installation](#-installation)
- [Usage](#-usage)
- [LLM Integration](#-llm-integration)
- [Future Enhancements](#-future-enhancements)

---

## ✨ Features

### Core Functionality

- **Multi-language Support**: English ↔ Vietnamese, Chinese ↔ Vietnamese (with pinyin)
- **Custom Knowledge**: Add programming notes, math concepts, or any study material
- **Intelligent Reminders**: Configurable auto-reminders every 1-3 hours
- **Multiple Quiz Modes**:
  - Translation (word → meaning)
  - Reverse translation (meaning → word)
  - Multiple choice
  - Fill-in-the-blank
  - True/False questions
- **Local LLM Integration**: Generate quiz questions from your notes using Ollama
- **Privacy-First**: All data stored locally on device

### User Experience

- Minimalist, distraction-free design
- Dark/Light mode support
- Smooth animations and transitions
- Quick answer feedback
- Progress tracking

---

## 🏗️ Architecture

### System Design

```
┌─────────────────────────────────────────────────────────┐
│                    Knop Application                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   UI Layer   │  │  Core Logic  │  │  Data Layer  │ │
│  │              │  │              │  │              │ │
│  │ - Quiz Popup │→→│ - Quiz Engine│→→│ - SQLite DB  │ │
│  │ - Home Screen│  │ - Scheduler  │  │ - Storage Mgr│ │
│  │ - Settings   │  │ - LLM Service│  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│         ↑                  ↑                  ↑         │
│         └──────────────────┴──────────────────┘         │
│                     Provider (State Mgmt)                │
│                                                          │
├─────────────────────────────────────────────────────────┤
│  External: Ollama (Optional Local LLM)                  │
└─────────────────────────────────────────────────────────┘
```

### Component Breakdown

**UI Layer**

- `QuizPopupScreen`: Modal quiz interface
- `HomeScreen`: Dashboard with statistics
- `SettingsScreen`: User preferences
- `VocabularyScreen`: Manage words
- `KnowledgeScreen`: Manage custom notes

**Core Logic**

- `FlashcardEngine`: Quiz generation and scoring
- `ReminderEngine`: Background notification scheduler
- `LLMQuestionGenerator`: Ollama integration for AI questions
- `QuizModeSelector`: Logic for different quiz types

**Data Layer**

- `StorageManager`: SQLite database operations
- `Models`: Data structures (Vocabulary, Knowledge, Quiz, Settings)

---

## 🔄 Data Flow

### 1. Adding Vocabulary

```
User Input → VocabularyScreen → StorageManager → SQLite DB
```

### 2. Quiz Generation

```
Timer Trigger → ReminderEngine → FlashcardEngine
    ↓
Select Items → Generate Question → Display Quiz Popup
    ↓
User Answer → Validate → Update Statistics → Next Question
```

### 3. LLM Question Generation

```
User Notes → KnowledgeScreen → LLMQuestionGenerator
    ↓
HTTP Request → Ollama (localhost:11434) → Parse Response
    ↓
Extract Questions → Store in DB → Available for Quizzes
```

---

## 🗄️ Database Schema

### SQLite Tables

**vocabulary**

```sql
CREATE TABLE vocabulary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  language TEXT NOT NULL,          -- 'en' or 'cn'
  word TEXT NOT NULL,
  pinyin TEXT,                     -- for Chinese only
  meaning_vi TEXT NOT NULL,
  example_sentence TEXT,
  difficulty INTEGER DEFAULT 1,    -- 1-5 scale
  times_correct INTEGER DEFAULT 0,
  times_shown INTEGER DEFAULT 0,
  last_shown DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**knowledge**

```sql
CREATE TABLE knowledge (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic TEXT NOT NULL,             -- e.g., "JavaScript", "Math"
  content TEXT NOT NULL,           -- original study notes
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**quiz_questions**

```sql
CREATE TABLE quiz_questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  knowledge_id INTEGER,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  question_type TEXT DEFAULT 'open',  -- 'open', 'multiple_choice', 'true_false'
  options TEXT,                       -- JSON array for multiple choice
  times_correct INTEGER DEFAULT 0,
  times_shown INTEGER DEFAULT 0,
  last_shown DATETIME,
  FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
);
```

**settings**

```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

**quiz_history**

```sql
CREATE TABLE quiz_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_type TEXT NOT NULL,         -- 'vocabulary' or 'knowledge'
  item_id INTEGER NOT NULL,
  was_correct BOOLEAN NOT NULL,
  answered_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### JSON Data Structure (Alternative)

If using JSON file storage:

```json
{
  "vocabulary": [
    {
      "id": 1,
      "language": "en",
      "word": "apple",
      "meaning_vi": "quả táo",
      "example_sentence": "I eat an apple every day",
      "difficulty": 1,
      "times_correct": 5,
      "times_shown": 7,
      "last_shown": "2025-11-08T10:30:00Z"
    },
    {
      "id": 2,
      "language": "cn",
      "word": "苹果",
      "pinyin": "píngguǒ",
      "meaning_vi": "quả táo",
      "difficulty": 2,
      "times_correct": 3,
      "times_shown": 5,
      "last_shown": "2025-11-07T14:20:00Z"
    }
  ],
  "knowledge": [
    {
      "id": 1,
      "topic": "JavaScript",
      "content": "Closures allow inner functions to access outer function variables...",
      "questions": [
        {
          "id": 1,
          "question": "What is a closure in JavaScript?",
          "answer": "A mechanism where inner functions can access outer variables",
          "question_type": "open",
          "times_correct": 2,
          "times_shown": 3
        }
      ]
    }
  ],
  "settings": {
    "reminder_interval_hours": 2,
    "active_hours_start": 8,
    "active_hours_end": 22,
    "enabled_modes": ["language", "knowledge"],
    "theme": "light",
    "questions_per_session": 3
  }
}
```

---

## 📦 Installation

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / Xcode (for mobile)
- Ollama (optional, for LLM features)

### Setup Steps

1. **Clone the repository**

```bash
git clone <repository-url>
cd knop_flashcard
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Configure Ollama (Optional)**

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a lightweight model
ollama pull phi3
```

4. **Run the app**

```bash
# Desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux

# Mobile
flutter run -d android
flutter run -d ios
```

---

## 🎮 Usage

### Adding Vocabulary

1. Navigate to "Vocabulary" tab
2. Click "Add Word"
3. Select language (English/Chinese)
4. Enter word, meaning, and optional example
5. For Chinese, pinyin is auto-detected or manually entered

### Adding Knowledge Notes

1. Navigate to "Knowledge" tab
2. Click "Add Note"
3. Enter topic and paste your study material
4. Click "Generate Questions" to use LLM
5. Review and edit generated questions

### Configuring Reminders

1. Go to Settings
2. Set reminder interval (1-3 hours)
3. Configure active hours (e.g., 8 AM - 10 PM)
4. Select quiz modes (Language/Knowledge/Both)
5. Set questions per session (1-5)

### Taking Quizzes

- Automatic popup appears based on schedule
- Answer the question
- Click "Show Answer" to reveal
- Mark yourself correct/incorrect
- Click "Next" for the next question

---

## 🤖 LLM Integration

### Ollama Setup

Knop uses **Ollama** for local LLM inference. It's completely optional and privacy-preserving.

**Supported Models:**

- `phi3` (lightweight, fast)
- `mistral` (balanced)
- `llama2` (more capable)

### Question Generation Prompt

```
Given the user's study notes below, generate 3 short quiz questions to test their understanding.

Notes:
{user_notes}

Output JSON format:
[
  {
    "question": "...",
    "answer": "...",
    "question_type": "open"
  },
  {
    "question": "...",
    "answer": "...",
    "question_type": "true_false"
  },
  {
    "question": "...",
    "answer": "...",
    "question_type": "multiple_choice",
    "options": ["A", "B", "C", "D"]
  }
]

Ensure questions are clear, concise, and test key concepts.
```

### API Integration

```dart
// Example Ollama API call
final response = await http.post(
  Uri.parse('http://localhost:11434/api/generate'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'model': 'phi3',
    'prompt': promptText,
    'stream': false,
  }),
);
```

---

## 🚀 Future Enhancements

### Phase 2 Features

- [ ] Spaced repetition algorithm (SM-2/Anki-style)
- [ ] Image support for vocabulary
- [ ] Audio pronunciation (TTS)
- [ ] Import/Export data (CSV, JSON)
- [ ] Cloud sync (optional, encrypted)
- [ ] Streak tracking and gamification
- [ ] Study statistics and insights

### Phase 3 Features

- [ ] Shared deck marketplace
- [ ] Collaborative learning
- [ ] Advanced LLM features (conversation practice)
- [ ] Multi-device sync
- [ ] Browser extension
- [ ] Mobile widgets

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🤝 Contributing

Contributions are welcome! Please read CONTRIBUTING.md for guidelines.

---

## 📧 Contact

For questions or feedback, open an issue on GitHub.

---

**Built with ❤️ for language learners and knowledge seekers**
