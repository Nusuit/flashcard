# Knop Flashcard

## Purpose

A flashcard application with AI-powered quiz generation using Gemini API. Supports vocabulary learning and custom knowledge notes with spaced repetition algorithm (SM-2).

## Features

- Quiz system with spaced repetition (SM-2 algorithm)
- AI-powered question generation and answer evaluation (Gemini 2.5 Flash)
- Vocabulary mode with simple flashcards
- Knowledge mode with AI-generated questions
- PDF import with text extraction
- SQLite database with performance optimization
- Quiz queue system with priority scheduling

## Tech Stack

- Flutter Desktop (Windows)
- SQLite with indexes for performance
- Gemini API for AI features
- Provider for state management

## How to Run

```bash
# Clone repository
git clone https://github.com/Nusuit/flashcard.git
cd knop_flashcard

# Install dependencies
flutter pub get

# Create .env file
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY

# Run on Windows
flutter run -d windows
```

## License

MIT License
