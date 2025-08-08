import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/constants.dart';

enum AIProvider {
  openai,
  anthropic,
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String get _openAIKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String get _anthropicKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  Future<String?> generateResponse({
    required String userMessage,
    required String context,
    AIProvider provider = AIProvider.openai,
  }) async {
    try {
      switch (provider) {
        case AIProvider.openai:
          return await _generateOpenAIResponse(userMessage, context);
        case AIProvider.anthropic:
          return await _generateAnthropicResponse(userMessage, context);
      }
    } catch (e) {
      print('Error generando respuesta de IA: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  Future<String?> _generateOpenAIResponse(String userMessage, String context) async {
    if (_openAIKey.isEmpty) {
      print('API Key de OpenAI no configurada');
      return _getFallbackResponse(userMessage);
    }

    try {
      final systemPrompt = _buildSystemPrompt(context);
      
      final url = Uri.parse('${AppConstants.openAiBaseUrl}/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage}
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content?.toString().trim();
      } else {
        print('Error OpenAI API: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error en OpenAI: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  Future<String?> _generateAnthropicResponse(String userMessage, String context) async {
    if (_anthropicKey.isEmpty) {
      print('API Key de Anthropic no configurada');
      return _getFallbackResponse(userMessage);
    }

    try {
      final systemPrompt = _buildSystemPrompt(context);
      
      final url = Uri.parse('${AppConstants.anthropicBaseUrl}/v1/messages');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _anthropicKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 200,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'][0]['text'];
        return content?.toString().trim();
      } else {
        print('Error Anthropic API: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error en Anthropic: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _buildSystemPrompt(String context) {
    return '''
Eres un asistente turístico amigable y conocedor que ayuda a los usuarios a descubrir lugares interesantes.

CONTEXTO ACTUAL:
$context

INSTRUCCIONES:
- Responde en español de forma natural y conversacional
- Sé entusiasta y descriptivo sobre los lugares
- Mantén las respuestas entre 1-3 frases
- Si no tienes información específica, sé honesto pero positivo
- Incluye datos interesantes, historia o curiosidades cuando sea relevante
- Invita al usuario a hacer más preguntas
- Adapta tu tono para ser cálido y acogedor

EJEMPLOS DE RESPUESTAS:
- "¡Qué lugar tan fascinante! La [nombre] es conocida por [dato interesante]. ¿Te gustaría saber más sobre su historia?"
- "Estás cerca de un sitio increíble. [Descripción breve y emocionante]. ¿Hay algo específico que te interese saber?"
''';
  }

  String _getFallbackResponse(String userMessage) {
    // Respuestas inteligentes basadas en patrones de preguntas
    final message = userMessage.toLowerCase();
    
    if (message.contains('historia') || message.contains('histórico')) {
      return 'Este lugar tiene una rica historia que se remonta a varios siglos. ¿Te gustaría saber sobre algún período específico?';
    }
    
    if (message.contains('cómo llegar') || message.contains('llegar')) {
      return 'Te encuentras muy cerca del lugar. Puedes llegar caminando fácilmente. ¿Necesitas direcciones más específicas?';
    }
    
    if (message.contains('horario') || message.contains('abierto')) {
      return 'Te recomiendo verificar los horarios actuales ya que pueden variar por temporada. ¿Hay algo más que te interese saber del lugar?';
    }
    
    if (message.contains('precio') || message.contains('entrada') || message.contains('cuesta')) {
      return 'Los precios pueden variar. Te sugiero consultar información actualizada. ¿Te interesa conocer qué más puedes hacer en la zona?';
    }
    
    if (message.contains('qué ver') || message.contains('qué hacer') || message.contains('visitar')) {
      return 'Hay muchas cosas interesantes que ver en esta zona. Desde arquitectura histórica hasta espacios culturales únicos. ¿Hay algún tipo de lugar que te interese más?';
    }
    
    return 'Es un lugar realmente interesante con mucho que ofrecer. ¿Hay algo específico que te gustaría saber sobre él?';
  }

  // Método para generar respuesta de bienvenida con contexto de POI
  Future<String> generateWelcomeMessage(String? poiContext) async {
    if (poiContext == null || poiContext.isEmpty) {
      return AppConstants.welcomeMessage;
    }

    final response = await generateResponse(
      userMessage: '¿Qué me puedes decir sobre este lugar?',
      context: poiContext,
    );

    return response ?? AppConstants.welcomeMessage;
  }

  // Método para respuestas específicas de turismo
  Future<String?> generateTourismResponse({
    required String question,
    required String locationContext,
    String? poiDetails,
  }) async {
    String fullContext = locationContext;
    if (poiDetails != null) {
      fullContext += '\n\nDetalles adicionales: $poiDetails';
    }

    return await generateResponse(
      userMessage: question,
      context: fullContext,
    );
  }
}
