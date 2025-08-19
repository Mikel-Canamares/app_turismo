import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../poi/models/poi_model.dart';
import 'package:geolocator/geolocator.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late final String _openaiApiKey;
  final String _openaiBaseUrl = 'https://api.openai.com/v1';
  final String _model = 'gpt-3.5-turbo';

  /// Inicializa el servicio con la API key
  void initialize() {
    _openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (_openaiApiKey.isEmpty) {
      print('⚠️ ADVERTENCIA: API key de OpenAI no encontrada en .env');
    } else {
      print('✅ AI Service inicializado con API key');
    }
  }

  /// Genera mensaje de bienvenida personalizado basado en la ubicación
  Future<String> generateWelcomeMessage({
    Position? position,
    PointOfInterest? nearbyPOI,
  }) async {
    try {
      String locationContext = '';
      
      if (position != null) {
        locationContext = 'El usuario está en las coordenadas ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        
        if (nearbyPOI != null) {
          locationContext += ' y cerca hay ${nearbyPOI.detailedDescription}';
        }
      }

      final prompt = '''
Eres un asistente turístico inteligente y amigable llamado "Turismo AI". 
Tu trabajo es ayudar a las personas a descubrir lugares interesantes y responder preguntas sobre turismo.

$locationContext

Genera un mensaje de bienvenida cálido, breve (máximo 3 frases) y personalizado. 
- Saluda al usuario
- Menciona que estás aquí para ayudarle con información turística
- Si hay un lugar cercano interesante, menciónalo brevemente
- Invítalo a hacer preguntas por voz

Habla de manera natural y conversacional en español.
''';

      final response = await _sendToOpenAI(prompt);
      
      if (response.isNotEmpty) {
        print('✅ Mensaje de bienvenida generado');
        return response;
      } else {
        return _getFallbackWelcomeMessage(nearbyPOI);
      }
      
    } catch (e) {
      print('❌ Error generando mensaje de bienvenida: $e');
      return _getFallbackWelcomeMessage(nearbyPOI);
    }
  }

  /// Genera respuesta turística basada en pregunta del usuario y contexto
  Future<String> generateTourismResponse({
    required String userQuestion,
    Position? userPosition,
    PointOfInterest? contextPOI,
    List<PointOfInterest>? nearbyPOIs,
  }) async {
    try {
      if (_openaiApiKey.isEmpty) {
        return _getFallbackTourismResponse(userQuestion, contextPOI);
      }

      // Construir contexto geográfico y turístico
      final context = _buildTourismContext(
        userPosition: userPosition,
        contextPOI: contextPOI,
        nearbyPOIs: nearbyPOIs,
      );

      final prompt = '''
Eres un asistente turístico experto y entusiasta llamado "Turismo AI".
Tu personalidad es amigable, informativa y apasionada por el turismo.

CONTEXTO ACTUAL:
$context

PREGUNTA DEL USUARIO: "$userQuestion"

INSTRUCCIONES:
1. Responde de manera conversacional y natural en español
2. USA ÚNICAMENTE la información de los lugares cercanos proporcionados en el contexto
3. NO inventes lugares que no están en la lista de POIs cercanos
4. Si no hay lugares interesantes cercanos, dilo honestamente
5. Menciona SOLO lugares que estén dentro del radio de búsqueda proporcionado
6. Incluye las distancias exactas mencionadas en el contexto
7. Mantén un tono entusiasta pero informativo
8. Limita tu respuesta a máximo 4-5 frases para que sea conversacional
9. Si no tienes información específica de la zona, sugiere usar la entrada de texto para preguntas más específicas

Responde como si fueras un guía turístico local experimentado hablando en persona.
''';

      final response = await _sendToOpenAI(prompt);
      
      if (response.isNotEmpty) {
        print('✅ Respuesta turística generada');
        return response;
      } else {
        return _getFallbackTourismResponse(userQuestion, contextPOI);
      }
      
    } catch (e) {
      print('❌ Error generando respuesta turística: $e');
      return _getFallbackTourismResponse(userQuestion, contextPOI);
    }
  }

  /// Genera respuesta general de IA
  Future<String> generateResponse(String prompt) async {
    try {
      if (_openaiApiKey.isEmpty) {
        print('❌ No se puede generar respuesta: API key no configurada');
        return 'Lo siento, no puedo procesar tu solicitud en este momento. Por favor, verifica la configuración.';
      }

      return await _sendToOpenAI(prompt);
      
    } catch (e) {
      print('❌ Error generando respuesta: $e');
      return 'Lo siento, ocurrió un error al procesar tu solicitud. ¿Podrías intentar de nuevo?';
    }
  }

  /// Envía prompt a OpenAI y obtiene respuesta
  Future<String> _sendToOpenAI(String prompt) async {
    try {
      final uri = Uri.parse('$_openaiBaseUrl/chat/completions');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      };

      final body = json.encode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 300,
        'temperature': 0.7,
        'top_p': 1.0,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      });

      print('🤖 Enviando consulta a OpenAI...');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout en consulta a OpenAI');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final choices = jsonResponse['choices'] as List;
        
        if (choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String;
          print('✅ Respuesta recibida de OpenAI');
          return content.trim();
        } else {
          throw Exception('Respuesta vacía de OpenAI');
        }
      } else {
        print('❌ Error de OpenAI: ${response.statusCode} - ${response.body}');
        throw Exception('Error de OpenAI: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error en comunicación con OpenAI: $e');
      rethrow;
    }
  }

  /// Construye contexto turístico para la IA
  String _buildTourismContext({
    Position? userPosition,
    PointOfInterest? contextPOI,
    List<PointOfInterest>? nearbyPOIs,
  }) {
    final context = StringBuffer();
    
    if (userPosition != null) {
      context.writeln('UBICACIÓN EXACTA DEL USUARIO:');
      context.writeln('- Coordenadas GPS: ${userPosition.latitude.toStringAsFixed(6)}, ${userPosition.longitude.toStringAsFixed(6)}');
      context.writeln('- Radio de búsqueda: 2 kilómetros');
      context.writeln('');
    }

    if (contextPOI != null) {
      context.writeln('LUGAR PRINCIPAL MÁS CERCANO:');
      context.writeln('- Nombre: ${contextPOI.name}');
      context.writeln('- Tipo: ${contextPOI.typeInSpanish}');
      context.writeln('- Distancia EXACTA: ${contextPOI.distance < 1000 ? "${contextPOI.distance.toStringAsFixed(0)} metros" : "${(contextPOI.distance/1000).toStringAsFixed(1)} kilómetros"}');
      context.writeln('- Coordenadas: ${contextPOI.latitude.toStringAsFixed(6)}, ${contextPOI.longitude.toStringAsFixed(6)}');
      
      if (contextPOI.description.isNotEmpty) {
        context.writeln('- Descripción: ${contextPOI.description}');
      }
      
      if (contextPOI.address.isNotEmpty) {
        context.writeln('- Dirección: ${contextPOI.address}');
      }
      context.writeln('');
    }

    if (nearbyPOIs != null && nearbyPOIs.isNotEmpty) {
      context.writeln('LISTA COMPLETA DE LUGARES CERCANOS (dentro de 2km):');
      for (int i = 0; i < nearbyPOIs.length && i < 5; i++) {
        final poi = nearbyPOIs[i];
        context.writeln('${i + 1}. ${poi.name} (${poi.typeInSpanish}) - ${poi.distance < 1000 ? "${poi.distance.toStringAsFixed(0)}m" : "${(poi.distance/1000).toStringAsFixed(1)}km"}');
      }
      context.writeln('');
      context.writeln('IMPORTANTE: Responde SOLO sobre estos lugares específicos. NO menciones lugares que no estén en esta lista.');
    } else {
      context.writeln('ATENCIÓN: No se encontraron lugares de interés turístico dentro de 2 kilómetros de la ubicación actual.');
      context.writeln('Informa al usuario que no hay POIs cercanos y sugiere que pregunte sobre algo específico.');
    }

    return context.toString();
  }

  /// Mensaje de bienvenida de respaldo
  String _getFallbackWelcomeMessage(PointOfInterest? nearbyPOI) {
    if (nearbyPOI != null) {
      return '¡Hola! Soy tu asistente turístico. Veo que estás cerca de ${nearbyPOI.name}. ¿Te gustaría saber más sobre este lugar o hay algo específico que te interese conocer? Puedes preguntarme por voz.';
    } else {
      return '¡Hola! Soy tu asistente turístico personal. Estoy aquí para ayudarte a descubrir lugares interesantes y responder tus preguntas sobre turismo. ¿Qué te gustaría saber?';
    }
  }

  /// Respuesta turística de respaldo
  String _getFallbackTourismResponse(String question, PointOfInterest? contextPOI) {
    if (contextPOI != null) {
      return 'Te encuentras cerca de ${contextPOI.detailedDescription}. Aunque no tengo información adicional en este momento, te recomiendo explorar la zona. ¿Hay algo específico que te gustaría saber sobre este lugar?';
    } else {
      return 'Es una pregunta interesante sobre "$question". Aunque no tengo información específica disponible ahora mismo, te sugiero explorar los alrededores para descubrir lugares interesantes. ¿Puedo ayudarte con algo más?';
    }
  }

  /// Verifica si el servicio está disponible
  bool isAvailable() {
    return _openaiApiKey.isNotEmpty;
  }
}