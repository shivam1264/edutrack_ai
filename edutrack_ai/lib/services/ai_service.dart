import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // API Keys
  static const String _groqKey = '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';
  
  static const List<String> _geminiKeys = [
    'AIzaSyCrZqo2GTpHxTHmNdE6OspuJPLIOHsGwaA',
    'AIzaSyAr3KS4FnywgFNwq655sA4m1F47B6fBp50',
  ];
  
  static const List<String> _geminiModels = [
    'gemini-1.5-flash',
    'gemini-pro',
  ];

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
    
    return await _exhaustAllOptions(systemInstruction, prompt);
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(String content) async {
    const systemInstruction = """
You are an AI Study Assistant. Your task is to summarize the provided academic content 
into short, highly effective Flashcards (Question on Front, Answer on Back). 
Return the output STRICTLY as a JSON list of objects: [{"q": "Short Question?", "a": "Short Answer"}]. 
Generate 5 to 10 flashcards maximum. Keep answers concise.
""";

    return await _exhaustAllOptions(systemInstruction, "Content:\n$content");
  }

  Future<List<Map<String, dynamic>>> _exhaustAllOptions(String system, String user) async {
    // 1. Try Groq (Llama-3) first if key is provided
    if (_groqKey.isNotEmpty) {
      try {
        print('Trying Groq (Llama-3-70b)...');
        return await _requestGroq(system, user);
      } catch (e) {
        print('Groq failed: $e');
      }
    }

    // 2. Try Gemini fallback chain
    final endpoints = ['v1', 'v1beta'];
    for (var key in _geminiKeys) {
      for (var model in _geminiModels) {
        for (var ver in endpoints) {
          try {
            print('Trying $model ($ver) with key: ${key.substring(0, 8)}...');
            return await _requestGemini(system, user, model: model, apiKey: key, apiVer: ver);
          } catch (e) {
            print('Failed $model ($ver): $e');
            continue;
          }
        }
      }
    }
    
    // ... rest of the mock logic ...
    print('⚠️ ALL AI MODELS FAILED. Returning Mock Data.');
    int requestedCount = int.tryParse(user.split('Create ')[1].split(' ')[0]) ?? 5;
    if (system.contains('Flashcards')) {
      return List.generate(requestedCount > 10 ? 10 : requestedCount, (i) => {
        "q": "Key concept ${i + 1} about $user?",
        "a": "Detailed explanation for concept ${i + 1}."
      });
    }
    return List.generate(requestedCount, (i) => {
      "text": "Concept analysis of ${user.split('Topic: ')[1].split(' |')[0]} (Part ${i + 1})?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOption": i % 4,
      "marks": 1.0,
      "type": "mcq"
    });
  }

  Future<List<Map<String, dynamic>>> _requestGroq(String system, String user) async {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        "model": "llama-3.1-70b-versatile",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": 0.5,
        "response_format": {"type": "json_object"}
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data['choices'][0]['message']['content'];
      // Handle cases where Groq might wrap JSON in a key or return a list
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded.containsKey('questions')) return List<Map<String, dynamic>>.from(decoded['questions']);
      if (decoded is Map && decoded.containsKey('flashcards')) return List<Map<String, dynamic>>.from(decoded['flashcards']);
      if (decoded is List) return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      return [Map<String, dynamic>.from(decoded)];
    } else {
      throw Exception('Groq Error (${response.statusCode}): ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> _requestGemini(String system, String user, 
      {required String model, required String apiKey, String apiVer = 'v1beta'}) async {
    final url = 'https://generativelanguage.googleapis.com/$apiVer/models/$model:generateContent?key=$apiKey';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [{"text": "$system\n\n$user"}]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 2048,
        }
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] == null || data['candidates'].isEmpty) throw Exception('Empty');
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(text);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
