// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'dart:async';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  /// Inicializa el servicio de reconocimiento de voz (MOCK)
  Future<bool> initialize() async {
    try {
      print('🎤 Inicializando servicio de reconocimiento de voz (MOCK)...');
      
      // Simular inicialización
      await Future.delayed(const Duration(milliseconds: 500));
      _isInitialized = true;
      
      print('✅ Servicio de reconocimiento de voz inicializado correctamente (MOCK)');
      print('🌍 Idiomas disponibles (MOCK): es_ES, en_US');
      
      return true;
      
    } catch (e) {
      print('❌ Error inicializando speech to text: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Verifica si el servicio tiene permisos (MOCK)
  Future<bool> get hasPermission async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// Solicita permisos para el reconocimiento de voz (MOCK)
  Future<bool> requestPermission() async {
    try {
      return await initialize();
    } catch (e) {
      print('❌ Error solicitando permisos de voz: $e');
      return false;
    }
  }

  /// Inicia la escucha de voz (MOCK)
  Future<String?> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String localeId = 'es_ES',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('❌ No se puede iniciar la escucha: servicio no inicializado');
        return null;
      }
    }

    if (_isListening) {
      print('⚠️ Ya se está escuchando');
      return null;
    }

    try {
      _lastWords = '';
      _confidence = 0.0;
      _isListening = true;
      
      print('🎤 Iniciando escucha de voz (MOCK)...');
      
      // Simular escucha por el tiempo especificado
      final duration = listenFor ?? const Duration(seconds: 5);
      await Future.delayed(duration);
      
      // Simular respuestas aleatorias
      final mockResponses = [
        "¿Qué puedo visitar aquí?",
        "Cuéntame sobre este lugar",
        "¿Cuál es la historia de este sitio?",
        "¿Qué hay de interesante cerca?",
        "Dime más sobre esta zona",
        "¿Hay algún museo por aquí?",
        "¿Dónde puedo comer algo bueno?",
        "¿Qué actividades puedo hacer?",
        "¿Hay algún parque cerca?",
        "Cuéntame curiosidades del lugar"
      ];
      
      final randomIndex = DateTime.now().second % mockResponses.length;
      _lastWords = mockResponses[randomIndex];
      _confidence = 0.85 + (DateTime.now().millisecond % 15) / 100; // 0.85-0.99
      _isListening = false;
      
      print('🗣️ Palabras reconocidas (MOCK): "${_lastWords}" (confianza: ${(_confidence * 100).toStringAsFixed(1)}%)');
      print('✅ Reconocimiento completado (MOCK): "$_lastWords"');
      
      return _lastWords;
      
    } catch (e) {
      print('❌ Error durante el reconocimiento de voz: $e');
      _isListening = false;
      return null;
    }
  }

  /// Detiene la escucha (MOCK)
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        _isListening = false;
        print('🛑 Escucha detenida (MOCK)');
      } catch (e) {
        print('❌ Error deteniendo la escucha: $e');
      }
    }
  }

  /// Cancela la escucha (MOCK)
  Future<void> cancel() async {
    if (_isListening) {
      try {
        _isListening = false;
        _lastWords = '';
        _confidence = 0.0;
        print('❌ Escucha cancelada (MOCK)');
      } catch (e) {
        print('❌ Error cancelando la escucha: $e');
      }
    }
  }

  /// Obtiene los idiomas disponibles (MOCK)
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return ['es_ES', 'en_US', 'fr_FR', 'de_DE', 'it_IT']; // Mock locales
  }

  /// Método conveniente para escuchar un comando específico (MOCK)
  Future<String?> listenForCommand({
    String? prompt,
    Duration timeout = const Duration(seconds: 15),
    String localeId = 'es_ES',
  }) async {
    if (prompt != null) {
      print('💭 Esperando comando (MOCK): $prompt');
    }
    
    return await startListening(
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
    );
  }

  /// Verifica si el reconocimiento de voz está disponible en el dispositivo (MOCK)
  Future<bool> isAvailable() async {
    return true; // Mock siempre disponible
  }

  /// Limpia recursos (MOCK)
  void dispose() {
    if (_isListening) {
      _isListening = false;
    }
    _isInitialized = false;
    _isListening = false;
    _lastWords = '';
    _confidence = 0.0;
    print('🗑️ SpeechService disposed (MOCK)');
  }
}