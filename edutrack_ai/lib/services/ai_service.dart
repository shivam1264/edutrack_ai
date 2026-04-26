import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _geminiKey = 'AIzaSyCrZqo2GTpHxTHmNdE6OspuJPLIOHsGwaA';
  
  String _getUrl(String model) => 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiKey';

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String topic,
    required String subject,
    required int count,
    required String difficulty,
    required String type,
  }) async {
    final systemInstruction = """
You are an expert Teacher. Generate a high-quality quiz in valid JSON format.
The response MUST be ONLY a JSON list of objects with this structure:
[{"text": "Sample Question", "options": ["A", "B", "C", "D"], "correctOption": 0, "marks": 1, "type": "mcq"}]
- For 'Short Answer', include empty options and -1 for correctOption, set type to 'short'.
- For 'True/False', use ['True', 'False'] as options.
- Difficulty: $difficulty
- Target: Class 9/10 students.
- Language: English.
""";

    final prompt = "Create $count $type questions for Topic: $topic | Subject: $subject. Return ONLY the JSON array.";
    
    try {
      return await _requestGemini(systemInstruction, prompt);
    } catch (e) {
      print('Flash failed, trying Pro fallback: $e');
      return await _requestGemini(systemInstruction, prompt, model: 'gemini-pro');
    }
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String content) async {
    const systemInstruction = """
You are an AI Study Assistant. Your task is to summarize the provided academic content 
into short, highly effective Flashcards (Question on Front, Answer on Back). 
Return the output STRICTLY as a JSON list of objects: [{"q": "Short Question?", "a": "Short Answer"}]. 
Generate 5 to 10 flashcards maximum. Keep answers concise.
""";

    try {
      return await _requestGemini(systemInstruction, "Content:\n$content");
    } catch (e) {
      print('Flash failed, trying Pro fallback: $e');
      return await _requestGemini(systemInstruction, "Content:\n$content", model: 'gemini-pro');
    }
  }

  Future<List<Map<String, dynamic>>> _requestGemini(String system, String user, {String model = 'gemini-1.5-flash-latest'}) async {
    final response = await http.post(
      Uri.parse(_getUrl(model)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$system\n\n$user"}
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 40));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(text);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Gemini Error (${response.statusCode}): ${response.body}');
    }
  }
}
