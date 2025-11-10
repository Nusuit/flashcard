# Knop Flashcard - Getting Started Guide

## Quick Start (5 minutes)

### 1. Install Flutter

If you don't have Flutter installed:

```bash
# Windows (using Chocolatey)
choco install flutter

# macOS (using Homebrew)
brew install flutter

# Or download from: https://flutter.dev/docs/get-started/install
```

### 2. Clone and Setup

```bash
cd d:\Code\Important\project\knop_flashcard
flutter pub get
```

### 3. Run the App

```bash
# For Windows desktop
flutter run -d windows

# For Android emulator
flutter run -d android

# For iOS simulator
flutter run -d ios
```

---

## Setting Up Ollama (AI Features)

### Install Ollama

```bash
# Windows/macOS/Linux
curl -fsSL https://ollama.com/install.sh | sh
```

### Pull a Model

```bash
# Lightweight model (recommended for testing)
ollama pull phi3

# More capable models
ollama pull mistral
ollama pull llama2
```

### Start Ollama Server

```bash
ollama serve
# Server runs on http://localhost:11434
```

---

## Adding Your First Content

### 1. Add Vocabulary

1. Launch the app
2. Navigate to "Vocabulary" tab
3. Click "Add Word"
4. Fill in:
   - Language: English or Chinese
   - Word: The term to learn
   - Meaning: Vietnamese translation
   - Example (optional): A sentence using the word
5. Click "Save"

### 2. Add Knowledge Notes

1. Navigate to "Knowledge" tab
2. Click "Add Note"
3. Fill in:
   - Topic: Subject area (e.g., "JavaScript")
   - Content: Paste your study notes
4. Click "Save"
5. Open the note and click "Generate Questions with AI"

### 3. Configure Reminders

1. Go to "Settings" tab
2. Set:
   - Reminder Interval: How often to quiz (1-3 hours)
   - Active Hours: When to show reminders (e.g., 8 AM - 10 PM)
   - Quiz Mode: Language, Knowledge, or Both
   - Questions per Session: 1-10 questions

### 4. Take a Quiz

1. Return to Dashboard
2. Click "Start Quiz Now" or "Quick Quiz"
3. Answer the questions
4. Mark yourself correct/incorrect
5. View your results!

---

## Understanding Quiz Modes

### Vocabulary Quiz Types

- **Word → Meaning**: Given English/Chinese, answer with Vietnamese
- **Meaning → Word**: Given Vietnamese, answer with English/Chinese
- **Pinyin → Meaning**: (Chinese only) Given pinyin, answer meaning
- **Pinyin → Character**: (Chinese only) Given pinyin, write character

### Knowledge Quiz Types

- **Open-ended**: Type your answer
- **Multiple Choice**: Select from 4 options
- **True/False**: Binary choice

---

## Tips for Best Results

### Vocabulary Learning

1. Add example sentences for better context
2. Start with 10-20 words, then expand
3. Mix easy and difficult words
4. Review regularly (use reminders!)

### Knowledge Notes

1. Keep notes concise (1-2 paragraphs)
2. Focus on key concepts
3. Use clear, simple language
4. Review AI-generated questions and edit if needed

### Reminder Settings

1. Start with longer intervals (3 hours)
2. Adjust based on your schedule
3. Set active hours to avoid late-night notifications
4. Use "Test Notification" to verify it works

---

## Troubleshooting

### App won't start

```bash
flutter clean
flutter pub get
flutter run
```

### Database errors

Delete the app and reinstall (data will be lost):

```bash
flutter clean
flutter run
```

### Ollama not connecting

1. Check if Ollama is running: `ollama list`
2. Verify endpoint in Settings: `http://localhost:11434`
3. Try pulling a model: `ollama pull phi3`
4. Restart Ollama: Kill process and run `ollama serve`

### Notifications not showing

1. Check app permissions in system settings
2. Verify active hours in Settings
3. Use "Test Notification" button
4. On Android, ensure battery optimization is disabled

---

## Sample Data for Testing

### English Vocabulary

```
Word: "apple" → Meaning: "quả táo"
Word: "book" → Meaning: "quyển sách"
Word: "computer" → Meaning: "máy tính"
```

### Chinese Vocabulary

```
Word: "苹果" → Pinyin: "píngguǒ" → Meaning: "quả táo"
Word: "书" → Pinyin: "shū" → Meaning: "quyển sách"
Word: "电脑" → Pinyin: "diànnǎo" → Meaning: "máy tính"
```

### Knowledge Note Example

```
Topic: JavaScript Closures

Content:
A closure is a function that has access to variables in its outer (enclosing)
function's scope, even after the outer function has returned. Closures are
created every time a function is created. They are useful for data privacy
and creating function factories.
```

---

## Next Steps

1. ✅ Add 20-30 vocabulary words
2. ✅ Create 5 knowledge notes with AI questions
3. ✅ Configure reminder schedule
4. ✅ Take your first quiz!
5. ✅ Check statistics in Dashboard
6. 🚀 Build a learning habit!

---

## Need Help?

- Read the full [README.md](README.md)
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Open an issue on GitHub
- Review [API_DOCS.md](API_DOCS.md) for development

Happy learning! 🎴✨
