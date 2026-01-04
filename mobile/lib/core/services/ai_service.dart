import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import 'package:caloric_mobile/core/config/app_config.dart';

class AiService {
  AiService() {
    OpenAI.apiKey = AppConfig.openAiApiKey;
  }

  Future<String?> getChatResponse({
    required String prompt,
    required String systemInstruction,
    List<Map<String, dynamic>> history = const [],
  }) async {
    try {
      final List<OpenAIChatCompletionChoiceMessageModel> messages = [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(systemInstruction),
          ],
        ),
        ...history.map((m) => OpenAIChatCompletionChoiceMessageModel(
          role: m['isUser'] ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(m['content']),
          ],
        )),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
          ],
        ),
      ];

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: messages,
      );

      return chatCompletion.choices.first.message.content?.first.text;
    } catch (e) {
      debugPrint('OpenAI Service Chat Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeFoodImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = 'Identify this food. Return ONLY a pure JSON object. No markdown. No chat. Format: {"foodName": "string", "calories": int, "protein": int, "carbs": int, "fat": int, "ingredients": [{"name": "string", "calories": int}]}. If unsure, estimate. If definitely not food, return {"error": "not_food"}.';

      // Using direct HTTP to ensure exact JSON structure for vision
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'response_format': {'type': 'json_object'},
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('OpenAI HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      final text = data['choices'][0]['message']['content'];
      debugPrint('OpenAI Service: Raw Response: $text');

      if (text == null) return null;
      return json.decode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OpenAI Service Image Analysis Error: $e');
      return null;
    }
  }
}
