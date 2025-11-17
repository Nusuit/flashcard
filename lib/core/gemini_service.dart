import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cached API response
class _CachedResponse {
  final String response;
  final DateTime timestamp;

  _CachedResponse(this.response, this.timestamp);
}

/// Service to interact with Google Gemini API
class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.5-flash';

  // Token limits for free tier safety
  static const int _maxAllowedTokens =
      150000; // Safe limit under 200K free tier
  static const int _defaultMaxOutputTokens = 1024;

  // Response cache to reduce API calls
  final Map<String, _CachedResponse> _responseCache = {};
  static const Duration _responseCacheExpiry = Duration(minutes: 10);

  /// Count tokens for a given prompt (cached)
  Future<int> _countTokens(String prompt) async {
    // Use simple estimation instead of API call for better performance
    return (prompt.length / 4).ceil(); // 1 token ≈ 4 chars
  }

  /// Calculate safe max output tokens based on input
  Future<int> _calculateSafeOutputTokens(
      String prompt, int preferredMax) async {
    final inputTokens = await _countTokens(prompt);
    final outputRoom = _maxAllowedTokens - inputTokens;

    if (outputRoom <= 0) {
      print('Warning: Input tokens ($inputTokens) exceed safe limit');
      return 100; // Minimum fallback
    }

    return outputRoom.clamp(100, preferredMax);
  }

  /// Clean cache periodically
  void _cleanCache() {
    final now = DateTime.now();
    _responseCache.removeWhere((key, value) {
      return now.difference(value.timestamp) > _responseCacheExpiry;
    });
  }

  /// Get cached response if available
  String? _getCachedResponse(String cacheKey) {
    _cleanCache();
    final cached = _responseCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _responseCacheExpiry) {
      return cached.response;
    }
    return null;
  }

  /// Cache a response
  void _cacheResponse(String cacheKey, String response) {
    _responseCache[cacheKey] = _CachedResponse(response, DateTime.now());

    // Limit cache size to prevent memory bloat
    if (_responseCache.length > 50) {
      _cleanCache();
    }
  }

  /// Send a chat message to Gemini
  Future<String> chat(String message,
      {List<Map<String, String>>? conversationHistory}) async {
    try {
      // Check cache first for repeated messages
      final cacheKey = 'chat_$message';
      final cached = _getCachedResponse(cacheKey);
      if (cached != null) {
        return cached;
      }

      final contents = <Map<String, dynamic>>[];

      // Add conversation history if provided (limit to last 5 messages)
      if (conversationHistory != null) {
        final recentHistory = conversationHistory.length > 5
            ? conversationHistory.sublist(conversationHistory.length - 5)
            : conversationHistory;

        for (var msg in recentHistory) {
          contents.add({
            'role': msg['role'],
            'parts': [
              {'text': msg['content']}
            ]
          });
        }
      }

      // Add current message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      });

      // Build prompt for token counting
      final promptText = contents.map((c) => c['parts'][0]['text']).join('\n');
      final safeOutputTokens =
          await _calculateSafeOutputTokens(promptText, _defaultMaxOutputTokens);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return text.trim();
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return 'Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này. Vui lòng thử lại sau.';
      }
    } catch (e) {
      print('Gemini Service Error: $e');
      return 'Đã xảy ra lỗi khi kết nối với AI. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }
  }

  /// Evaluate a user's answer to a question
  Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String userAnswer,
    required String context,
  }) async {
    try {
      final prompt = '''
Bạn là một giáo viên đang đánh giá câu trả lời của học sinh.

Câu hỏi: $question

Bối cảnh kiến thức: $context

Câu trả lời của học sinh: $userAnswer

Hãy đánh giá câu trả lời này và trả về JSON với format sau:
{
  "isCorrect": true/false,
  "score": 0-100,
  "feedback": "Nhận xét chi tiết về câu trả lời",
  "suggestion": "Gợi ý để cải thiện (nếu cần)"
}

Chỉ trả về JSON, không có text khác.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 512);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 20,
            'topP': 0.8,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Clean up the response to extract JSON
        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7);
        }
        if (text.startsWith('```')) {
          text = text.substring(3);
        }
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3);
        }
        text = text.trim();

        final evaluation = jsonDecode(text) as Map<String, dynamic>;
        return evaluation;
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return {
          'isCorrect': false,
          'score': 0,
          'feedback': 'Không thể đánh giá câu trả lời lúc này.',
          'suggestion': 'Vui lòng thử lại sau.'
        };
      }
    } catch (e) {
      print('Gemini Evaluation Error: $e');
      return {
        'isCorrect': false,
        'score': 0,
        'feedback': 'Đã xảy ra lỗi khi đánh giá câu trả lời.',
        'suggestion': 'Vui lòng thử lại sau.'
      };
    }
  }

  /// Generate a question based on knowledge content
  Future<String> generateQuestion(String knowledgeContent) async {
    try {
      final prompt = '''
Dựa trên kiến thức sau, hãy tạo một câu hỏi để kiểm tra sự hiểu biết:

$knowledgeContent

Tạo một câu hỏi ngắn gọn, rõ ràng và có ý nghĩa. Chỉ trả về câu hỏi, không giải thích.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 256);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return text.trim();
      } else {
        return 'Giải thích nội dung sau: ${knowledgeContent.substring(0, knowledgeContent.length > 50 ? 50 : knowledgeContent.length)}...';
      }
    } catch (e) {
      print('Gemini Question Generation Error: $e');
      return 'Giải thích nội dung này.';
    }
  }

  /// Generate vocabulary metadata (part of speech, example, context)
  Future<Map<String, dynamic>> generateVocabularyMetadata({
    required String word,
    required String language,
    required String meaning,
  }) async {
    try {
      final prompt = '''
Từ vựng: $word ($language)
Nghĩa tiếng Việt: $meaning

Hãy tạo metadata cho từ vựng này theo format JSON:
{
  "partOfSpeech": "noun/verb/adjective/etc",
  "exampleSentence": "Câu ví dụ tiếng $language",
  "exampleTranslation": "Dịch nghĩa tiếng Việt",
  "context": "Ngữ cảnh sử dụng, tips học",
  "tags": ["tag1", "tag2"]
}

Chỉ trả về JSON, không có text khác.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 512);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        text = _cleanJsonResponse(text);
        return jsonDecode(text) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Vocabulary metadata generation error: $e');
    }

    return {
      'partOfSpeech': 'unknown',
      'exampleSentence': '',
      'context': '',
      'tags': []
    };
  }

  /// Generate flashcards from PDF content
  Future<List<Map<String, dynamic>>> generateFlashcardsFromPdf(
      String pdfContent) async {
    try {
      final prompt = '''
Tạo flashcards từ nội dung PDF sau:

$pdfContent

Trả về JSON array với format:
[
  {
    "question": "Câu hỏi",
    "answer": "Đáp án",
    "type": "open/multipleChoice/trueFalse",
    "options": ["A", "B", "C", "D"] // chỉ cho multipleChoice
  }
]

Tạo tối đa 10 câu hỏi chất lượng cao. Chỉ trả về JSON array, không có text khác.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 2048);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        text = _cleanJsonResponse(text);
        return List<Map<String, dynamic>>.from(jsonDecode(text) as List);
      }
    } catch (e) {
      print('PDF flashcard generation error: $e');
    }

    return [];
  }

  /// Summarize knowledge content
  Future<String> summarizeKnowledge(String content) async {
    try {
      final prompt = '''
Tóm tắt kiến thức sau một cách ngắn gọn, rõ ràng (3-5 câu):

$content

Chỉ trả về phần tóm tắt, không có tiêu đề hay giới thiệu.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 512);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return text.trim();
      }
    } catch (e) {
      print('Knowledge summarization error: $e');
    }

    return content.substring(0, content.length > 200 ? 200 : content.length) +
        '...';
  }

  /// Generate quiz from chat conversation
  Future<Map<String, dynamic>?> generateQuizFromChat(
      List<Map<String, String>> conversation) async {
    try {
      final chatText = conversation
          .map((msg) => '${msg['role']}: ${msg['content']}')
          .join('\n');

      final prompt = '''
Dựa trên đoạn chat sau, tạo 1 câu hỏi quiz:

$chatText

Trả về JSON:
{
  "question": "Câu hỏi",
  "answer": "Đáp án",
  "type": "open",
  "context": "Bối cảnh từ đoạn chat"
}

Chỉ trả về JSON, không có text khác.
''';

      final safeOutputTokens = await _calculateSafeOutputTokens(prompt, 512);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': safeOutputTokens,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        text = _cleanJsonResponse(text);
        return jsonDecode(text) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Chat quiz generation error: $e');
    }

    return null;
  }

  /// Helper to clean JSON response from markdown code blocks
  String _cleanJsonResponse(String text) {
    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    }
    if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}
