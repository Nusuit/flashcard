import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_question.dart';
import '../models/knowledge.dart';

/// Service to integrate with Ollama for LLM-based question generation
class LLMQuestionGenerator {
  final String endpoint;
  final String model;

  LLMQuestionGenerator({
    this.endpoint = 'http://localhost:11434',
    this.model = 'phi3',
  });

  /// Check if Ollama is available
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$endpoint/api/tags'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available models
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/api/tags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        return models.map((m) => m['name'] as String).toList();
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    return [];
  }

  /// Generate quiz questions from knowledge content
  Future<List<QuizQuestion>> generateQuestions({
    required Knowledge knowledge,
    int numberOfQuestions = 3,
  }) async {
    try {
      final prompt = _buildPrompt(knowledge.content, numberOfQuestions);
      final response = await _callOllama(prompt);
      
      if (response != null) {
        return _parseQuestions(response, knowledge.id);
      }
    } catch (e) {
      print('Error generating questions: $e');
      throw Exception('Failed to generate questions: $e');
    }
    
    return [];
  }

  /// Build the prompt for question generation
  String _buildPrompt(String content, int count) {
    return '''Given the following study notes, generate exactly $count short quiz questions to test understanding.

Study Notes:
$content

Instructions:
- Create clear, concise questions that test key concepts
- Include a mix of question types: open-ended, true/false, and multiple choice
- For multiple choice, provide 4 options (A, B, C, D) with only one correct answer
- Ensure answers are accurate and based on the provided content

Output your response as a JSON array with this exact format:
[
  {
    "question": "What is...",
    "answer": "The correct answer",
    "question_type": "open"
  },
  {
    "question": "True or False: ...",
    "answer": "True",
    "question_type": "true_false"
  },
  {
    "question": "Which of the following...",
    "answer": "B",
    "question_type": "multiple_choice",
    "options": ["A) First option", "B) Correct option", "C) Third option", "D) Fourth option"]
  }
]

Generate exactly $count questions now:''';
  }

  /// Call Ollama API
  Future<String?> _callOllama(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
          },
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      } else {
        print('Ollama API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling Ollama: $e');
      throw Exception('Failed to connect to Ollama: $e');
    }
    return null;
  }

  /// Parse LLM response into QuizQuestion objects
  List<QuizQuestion> _parseQuestions(String response, int? knowledgeId) {
    try {
      // Extract JSON from response (LLM might add extra text)
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON array found in response');
      }

      final jsonStr = jsonMatch.group(0)!;
      final questionsJson = jsonDecode(jsonStr) as List;

      return questionsJson.map((json) {
        final questionType = _parseQuestionType(json['question_type'] as String);
        
        return QuizQuestion(
          knowledgeId: knowledgeId,
          question: json['question'] as String,
          answer: json['answer'] as String,
          questionType: questionType,
          options: json['options'] != null
              ? List<String>.from(json['options'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error parsing questions: $e');
      print('Response was: $response');
      
      // Fallback: create a generic question
      return [
        QuizQuestion(
          knowledgeId: knowledgeId,
          question: 'Unable to generate questions. Please try again.',
          answer: 'N/A',
          questionType: QuestionType.open,
        ),
      ];
    }
  }

  /// Parse question type string to enum
  QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'open':
      case 'open_ended':
        return QuestionType.open;
      case 'multiple_choice':
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'true_false':
      case 'truefalse':
        return QuestionType.trueFalse;
      default:
        return QuestionType.open;
    }
  }

  /// Generate questions with custom prompt
  Future<List<QuizQuestion>> generateCustomQuestions({
    required String customPrompt,
    int? knowledgeId,
  }) async {
    try {
      final response = await _callOllama(customPrompt);
      if (response != null) {
        return _parseQuestions(response, knowledgeId);
      }
    } catch (e) {
      print('Error generating custom questions: $e');
      throw Exception('Failed to generate custom questions: $e');
    }
    return [];
  }

  /// Test connection and generate a simple question
  Future<String?> testConnection() async {
    try {
      final response = await _callOllama(
        'Generate one simple quiz question about programming. Reply with just: Question: [question] Answer: [answer]',
      );
      return response;
    } catch (e) {
      return null;
    }
  }
}
