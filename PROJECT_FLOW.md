# Knop Flashcard - Complete Project Flow

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      KNOP FLASHCARD APP                         │
│                   (Flutter Desktop - Windows)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐      ┌──────────────┐
│     UI       │    │   Business   │      │     Data     │
│   Layer      │◄───│    Logic     │◄─────│    Layer     │
│  (Screens/   │    │  (Core/      │      │  (Models/    │
│   Widgets)   │    │   Providers) │      │   Storage)   │
└──────────────┘    └──────────────┘      └──────────────┘
```

---

## 📂 Project Structure

```
knop_flashcard/
├── lib/
│   ├── main.dart                    # Entry point, .env loader
│   │
│   ├── core/                        # Business Logic Layer
│   │   ├── flashcard_engine.dart    # Flashcard display logic
│   │   ├── llm_question_generator.dart # LLM question generation
│   │   ├── reminder_engine.dart     # Notification system
│   │   ├── storage_manager.dart     # SQLite database manager
│   │   ├── gemini_service.dart      # Gemini API integration
│   │   ├── quiz_scheduler.dart      # Quiz scheduling system
│   │   └── timezone_stub.dart       # Timezone utilities
│   │
│   ├── models/                      # Data Models
│   │   ├── knowledge.dart           # Knowledge/Project model
│   │   ├── vocabulary.dart          # Vocabulary model
│   │   ├── quiz_question.dart       # Quiz question model
│   │   ├── quiz_history.dart        # Quiz history model
│   │   └── app_settings.dart        # App settings model
│   │
│   ├── providers/                   # State Management
│   │   └── app_state_provider.dart  # Global app state (Provider)
│   │
│   ├── screens/                     # UI Screens
│   │   ├── new_home_screen.dart     # Dashboard (main)
│   │   ├── knowledge_screen.dart    # Knowledge list (legacy)
│   │   ├── knowledge_detail_screen.dart # Knowledge detail + PDF
│   │   ├── vocabulary_screen.dart   # Vocabulary management
│   │   ├── quiz_screen.dart         # Quiz screen
│   │   └── settings_screen.dart     # Settings
│   │
│   └── widgets/                     # Reusable Widgets
│       ├── create_knowledge_dialog.dart # Create/import dialog
│       ├── flashcard_overlay.dart   # Flashcard popup
│       ├── review_analytics_dialog.dart # Analytics popup
│       ├── chat_bubble.dart         # AI chat widget
│       └── quiz_popup.dart          # Quiz popup widget
│
├── .env                             # API keys (gitignored)
├── .env.example                     # Template
├── pubspec.yaml                     # Dependencies
└── [Docs...]                        # Documentation files
```

---

## 🔄 Complete Application Flow

### **1. App Startup Flow**

```
main.dart
    │
    ├─► Load .env file (dotenv.load)
    │
    ├─► Initialize SQLite
    │   └─► sqfliteFfiInit() for Windows
    │
    ├─► Initialize StorageManager
    │   └─► Create/Migrate Database
    │       ├─► knowledge table (v3)
    │       ├─► vocabulary table
    │       ├─► quiz_questions table
    │       └─► quiz_history table
    │
    ├─► Initialize ReminderEngine (Mobile only)
    │   ├─► Request notification permissions
    │   └─► Setup local notifications
    │
    └─► Launch KnopApp
        └─► MaterialApp
            └─► ChangeNotifierProvider (AppStateProvider)
                └─► NewHomeScreen (Root)
```

### **2. Home Screen Initialization**

```
NewHomeScreen.initState()
    │
    ├─► Setup QuizScheduler
    │   ├─► Set callback: onQuizReady
    │   └─► Start periodic timer (30 min)
    │
    ├─► Load AppStateProvider
    │   ├─► getAllKnowledge()
    │   └─► getAllVocabulary()
    │
    └─► Build UI
        ├─► Sidebar (navigation)
        ├─► Main content (dashboard/list)
        ├─► Flashcard overlay (conditional)
        ├─► Quiz popup (conditional)
        └─► Chat bubble (always visible)
```

---

## 📊 Feature Flows

### **A. Knowledge Management Flow**

```
USER ACTION: Create New Knowledge
         │
         ▼
┌─────────────────────────┐
│ Click "Tạo mới" button  │
└──────────┬──────────────┘
           │
           ▼
┌──────────────────────────────┐
│ CreateKnowledgeDialog opens  │
│ Options:                     │
│ 1. Manual Input              │
│ 2. Import from PDF           │
└──────────┬───────────────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐   ┌──────────┐
│ Manual │   │ PDF      │
│ Input  │   │ Import   │
└───┬────┘   └────┬─────┘
    │             │
    │             ▼
    │   ┌──────────────────────┐
    │   │ FilePicker.pickFiles │
    │   └────────┬─────────────┘
    │            │
    │            ▼
    │   ┌──────────────────────┐
    │   │ PdfDocument.load     │
    │   │ Extract text         │
    │   └────────┬─────────────┘
    │            │
    └────────┬───┘
             │
             ▼
    ┌────────────────────┐
    │ Save to Database   │
    │ (insertKnowledge)  │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Update UI State    │
    │ (AppStateProvider) │
    └────────────────────┘
```

### **B. Vocabulary Flow**

```
USER: Add Vocabulary
         │
         ▼
┌──────────────────────┐
│ VocabularyScreen     │
│ Input: word|meaning  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│ Parse input:             │
│ "hello|xin chào"         │
│ → word: "hello"          │
│ → meaning: "xin chào"    │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│ insertVocabulary()       │
│ (storage_manager)        │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│ Auto-generate questions  │
│ (LLM or template)        │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────┐
│ Save quiz_questions      │
│ with knowledge_id        │
└──────────────────────────┘
```

### **C. Quiz System Flow** (See QUIZ_FLOW.md for details)

```
Timer (30min) OR Manual Button
         │
         ▼
┌─────────────────────────┐
│ QuizScheduler triggers  │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Get Knowledge           │
│ Filter by reminderTime  │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Get Questions           │
│ Sort by needsPractice   │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Show QuizPopup          │
│ (top-right corner)      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ User answers            │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ GeminiService           │
│ evaluateAnswer()        │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Show results + feedback │
│ Update question stats   │
└─────────────────────────┘
```

### **D. Chat with AI Flow**

```
USER: Click Chat Bubble
         │
         ▼
┌─────────────────────────┐
│ Expand ChatBubble       │
│ (bottom-right)          │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ User types message      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Build conversation      │
│ history (role/content)  │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Calculate safe tokens   │
│ (_countTokens API)      │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Send to Gemini API      │
│ (gemini_service.chat)   │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│ Display AI response     │
│ Save to conversation    │
└─────────────────────────┘
```

### **E. PDF Import Flow**

```
USER: Import PDF to Knowledge
         │
         ▼
┌─────────────────────────────┐
│ KnowledgeDetailScreen       │
│ Click "Import PDF" button   │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ FilePicker.pickFiles()      │
│ (type: [pdf])               │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Copy file to app directory  │
│ (path_provider)             │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Update Knowledge.pdfFiles   │
│ (List<String> paths)        │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Save to database            │
│ (updateKnowledge)           │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Display PDF list in UI      │
│ (with delete option)        │
└─────────────────────────────┘
```

---

## 🗄️ Database Schema

### **Tables Structure**

```sql
-- Knowledge/Projects
CREATE TABLE knowledge (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic TEXT NOT NULL,
  content TEXT NOT NULL,
  mode TEXT DEFAULT 'knowledge',
  reminder_time TEXT,
  pdf_files TEXT,              -- JSON array
  description TEXT,
  last_modified TEXT
);

-- Vocabulary
CREATE TABLE vocabulary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example TEXT,
  created_at TEXT
);

-- Quiz Questions
CREATE TABLE quiz_questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  knowledge_id INTEGER,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  question_type TEXT DEFAULT 'open',
  options TEXT,                -- JSON array
  times_correct INTEGER DEFAULT 0,
  times_shown INTEGER DEFAULT 0,
  last_shown TEXT,
  FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
);

-- Quiz History
CREATE TABLE quiz_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  knowledge_id INTEGER,
  score REAL,
  completed_at TEXT,
  FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
);
```

### **Relationships**

```
knowledge (1) ───┬─── (N) quiz_questions
                 └─── (N) quiz_history

vocabulary (independent, no FK)
```

---

## 🔌 External Integrations

### **1. Gemini AI (Google)**

```
API: generativelanguage.googleapis.com/v1beta
Model: gemini-2.5-flash

Endpoints Used:
├── countTokens        → Count input tokens
├── generateContent    → Chat & evaluation
└── (future) generateQuestion → Auto question generation

Rate Limits:
├── Free Tier: 1500 requests/day
├── Token Limit: 200K/request (we use 150K safe)
└── RPM: 15 requests/minute
```

### **2. Local Storage (SQLite)**

```
Package: sqflite (mobile) / sqflite_common_ffi (desktop)
Location:
├── Windows: %APPDATA%\knop_flashcard\database.db
├── MacOS: ~/Library/Application Support/knop_flashcard/
└── Linux: ~/.local/share/knop_flashcard/

Migration System:
└── Version-based (currently v3)
    └── Automatic upgrade in initDatabase()
```

### **3. PDF Processing**

```
Package: syncfusion_flutter_pdf
Capabilities:
├── Load PDF from file
├── Extract text content
└── Parse pages

Limitations:
├── Text-based PDFs only (no OCR)
└── Images not extracted
```

---

## 🎨 UI Architecture

### **Navigation Structure**

```
NewHomeScreen (Root)
    │
    ├─► Sidebar
    │   ├─► Dashboard
    │   ├─► Knowledge List
    │   ├─► Vocabulary
    │   ├─► Quiz
    │   └─► Settings
    │
    ├─► Main Content Area
    │   └─► Dynamic content based on selection
    │
    └─► Floating Overlays
        ├─► Flashcard Overlay (center)
        ├─► Quiz Popup (top-right)
        └─► Chat Bubble (bottom-right)
```

### **State Management**

```
Provider Pattern (package: provider)

AppStateProvider (Global State)
├── knowledgeList: List<Knowledge>
├── vocabularyList: List<Vocabulary>
├── quizHistory: List<QuizHistory>
│
Methods:
├── loadKnowledge()
├── addKnowledge()
├── updateKnowledge()
├── deleteKnowledge()
├── loadVocabulary()
└── refreshAll()

Usage:
Provider.of<AppStateProvider>(context, listen: false)
context.watch<AppStateProvider>()
```

---

## ⚙️ Configuration & Settings

### **Environment Variables (.env)**

```bash
GEMINI_API_KEY=AIza...your_key
```

### **App Settings (SharedPreferences - Future)**

```dart
// Planned settings
{
  "quizInterval": 30,           // minutes
  "theme": "light",
  "language": "vi",
  "notificationsEnabled": true,
  "autoBackup": false
}
```

---

## 📈 Performance Optimizations

### **1. Database**

```dart
// Batch operations
await db.transaction((txn) async {
  for (var q in questions) {
    await txn.insert('quiz_questions', q.toMap());
  }
});

// Indexes (Future)
CREATE INDEX idx_knowledge_id ON quiz_questions(knowledge_id);
CREATE INDEX idx_reminder_time ON knowledge(reminder_time);
```

### **2. API Calls**

```dart
// Token limiting
- Count tokens before request
- Dynamic maxOutputTokens
- Fallback to estimate if API fails

// Caching (Future)
- Cache chat history in memory
- Store common responses locally
```

### **3. UI**

```dart
// Lazy loading
- Questions loaded on-demand
- PDF text extracted only when needed

// Debouncing
- Search input debounced (500ms)
- Auto-save after typing stops
```

---

## 🐛 Error Handling Strategy

```
Layer 1: UI Layer
├── try-catch in async operations
├── Show SnackBar for user errors
└── Fallback UI for failed states

Layer 2: Business Logic
├── Graceful degradation
├── Default values on failure
└── Log errors to console

Layer 3: Data Layer
├── Database constraint checks
├── Transaction rollbacks
└── Validate before insert/update

API Errors:
├── 400 → "Invalid API key"
├── 429 → "Quota exceeded, wait..."
├── 404 → "Model not found"
└── 500 → "Service error, retry"
```

---

## 🚀 Deployment Flow

### **Build for Windows**

```bash
# 1. Install dependencies
flutter pub get

# 2. Build release
flutter build windows --release

# 3. Output location
build/windows/x64/runner/Release/knop_flashcard.exe

# 4. Package (manual)
- Copy .dll files
- Include .env.example
- Create installer (optional)
```

### **Versioning**

```yaml
# pubspec.yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD
```

---

## 📊 Data Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│                    USER ACTIONS                         │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│                  UI LAYER (Screens/Widgets)             │
│  - Capture user input                                   │
│  - Display data                                         │
│  - Handle gestures                                      │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│            STATE MANAGEMENT (Provider)                  │
│  - AppStateProvider                                     │
│  - Notify listeners on changes                          │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│           BUSINESS LOGIC (Core Services)                │
│  - QuizScheduler                                        │
│  - GeminiService                                        │
│  - ReminderEngine                                       │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│              DATA LAYER (Storage)                       │
│  - StorageManager (SQLite)                              │
│  - File System (PDFs)                                   │
│  - SharedPreferences (settings)                         │
└─────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│           EXTERNAL SERVICES                             │
│  - Gemini API (AI)                                      │
│  - Notifications (System)                               │
└─────────────────────────────────────────────────────────┘
```

---

## 🔮 Future Roadmap

### **Phase 1: Core Features (Completed)**

- ✅ Knowledge management
- ✅ Vocabulary system
- ✅ Quiz popup
- ✅ AI chat integration
- ✅ PDF import

### **Phase 2: Intelligence (In Progress)**

- ⏳ LLM question generation
- ⏳ Spaced repetition algorithm
- ⏳ Smart scheduling

### **Phase 3: Enhancement**

- 📋 Cloud sync
- 📋 Mobile version (iOS/Android)
- 📋 Voice input/output
- 📋 Collaborative learning
- 📋 Analytics dashboard

### **Phase 4: Gamification**

- 📋 Streaks & achievements
- 📋 Leaderboards
- 📋 Daily challenges
- 📋 Rewards system

---

## 🛠️ Development Setup

### **Prerequisites**

```bash
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Visual Studio 2022 (Windows)
- Git
```

### **Setup Steps**

```bash
# 1. Clone repo
git clone https://github.com/Nusuit/flashcard.git

# 2. Install dependencies
cd knop_flashcard
flutter pub get

# 3. Create .env
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY

# 4. Run
flutter run -d windows
```

### **Project Commands**

```bash
# Development
flutter run -d windows          # Run debug
flutter run --release           # Run release mode
r                               # Hot reload
R                               # Hot restart

# Build
flutter build windows           # Build release
flutter clean                   # Clean build cache

# Testing
flutter test                    # Run tests
flutter analyze                 # Static analysis

# Database
# View: Use DB Browser for SQLite
# Location: %APPDATA%\knop_flashcard\database.db
```

---

## 📚 Key Dependencies

```yaml
# Core
flutter: SDK
provider: ^6.1.1 # State management

# Database
sqflite_common_ffi: ^2.3.0 # Desktop SQLite

# UI
fl_chart: ^0.66.0 # Charts
google_fonts: ^6.1.0 # Fonts

# Files
file_picker: ^6.1.1 # File picker
syncfusion_flutter_pdf: ^24.2.9 # PDF processing

# API
http: ^1.2.0 # HTTP client
flutter_dotenv: ^5.1.0 # .env loader

# Utilities
intl: ^0.18.1 # Internationalization
shared_preferences: ^2.2.2 # Local storage
```

---

## 🏁 Summary

Knop Flashcard là một ứng dụng flashcard thông minh với:

1. **Auto Quiz System** - Tự động kiểm tra theo lịch
2. **AI Integration** - Gemini AI cho chat & evaluation
3. **PDF Import** - Import kiến thức từ PDF
4. **Smart Scheduling** - Ưu tiên câu hỏi cần ôn
5. **Token Quota Protection** - An toàn với API limits

**Tech Stack:**

- Flutter (Desktop - Windows)
- SQLite (Local database)
- Gemini AI (Google)
- Provider (State management)

**Architecture:**

- Layered architecture (UI → Logic → Data)
- Singleton patterns (QuizScheduler, Storage)
- Provider pattern for state
- Event-driven quiz system
