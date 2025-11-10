# Contributing to Knop

Thank you for your interest in contributing to Knop! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - System information (OS, Flutter version)

### Suggesting Features

1. Open an issue with the "enhancement" label
2. Describe the feature and its benefits
3. Provide examples of how it would work
4. Discuss with maintainers before implementation

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**

   - Follow Dart style guidelines
   - Add comments for complex logic
   - Update documentation as needed

4. **Test your changes**

   ```bash
   flutter test
   flutter analyze
   ```

5. **Commit with clear messages**

   ```bash
   git commit -m "Add: Brief description of feature"
   ```

6. **Push to your fork**

   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Describe your changes
   - Reference related issues
   - Include screenshots for UI changes

## Development Setup

1. Install Flutter SDK (3.0+)
2. Clone the repository
3. Run `flutter pub get`
4. Install Ollama (optional, for LLM features)
5. Run `flutter run` to start development

## Code Style

- Use `dart format` for formatting
- Follow Flutter best practices
- Use meaningful variable names
- Add dartdoc comments for public APIs
- Keep functions focused and small

## Testing

- Write unit tests for business logic
- Add widget tests for UI components
- Ensure all tests pass before submitting PR

## Documentation

- Update README.md for user-facing changes
- Update ARCHITECTURE.md for design changes
- Add API documentation for new public methods
- Include code examples where helpful

## Questions?

Open an issue or reach out to maintainers for guidance.

Thank you for contributing! 🎉
