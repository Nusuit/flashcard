import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Count tokens for a given prompt
  Future<int> _countTokens(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:countTokens?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['totalTokens'] as int? ?? 0;
      }
    } catch (e) {
      print('Token counting error: $e');
    }
    // Return conservative estimate if counting fails
    return (prompt.length / 4).ceil(); // Rough estimate: 1 token ≈ 4 chars
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

  /// Send a chat message to Gemini
  Future<String> chat(String message,
      {List<Map<String, String>>? conversationHistory}) async {
    try {
      final contents = <Map<String, dynamic>>[];

      // Add conversation history if provided
      if (conversationHistory != null) {
        for (var msg in conversationHistory) {
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
}
