// import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/constants.dart';
import 'dart:async';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  // final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  /// Inicializa el servicio de TTS (MOCK)
  Future<void> initialize() async {
    try {
      print('🔊 Inicializando servicio de TTS (MOCK)...');

      // Simular inicialización
      await Future.delayed(const Duration(milliseconds: 300));

      // Simular configuración de idioma español
      await setLanguage('es-ES');

      // Simular configuración de velocidad y tono
      await setSpeechRate(0.6); // Velocidad moderada
      await setPitch(1.0); // Tono normal
      await setVolume(0.8); // Volumen alto

      // Simular idiomas disponibles
      print('🌍 Idiomas TTS disponibles (MOCK): es-ES, en-US, fr-FR, de-DE, it-IT');

      _isInitialized = true;
      print('✅ TTS inicializado correctamente (MOCK)');
      
    } catch (e) {
      print('❌ Error inicializando TTS: $e');
      _isInitialized = false;
    }
  }

  /// Reproduce texto usando TTS (MOCK)
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      print('❌ TTS no inicializado, no se puede hablar');
      return;
    }

    try {
      // Detener cualquier habla anterior
      if (_isSpeaking) {
        await stop();
      }

      if (text.trim().isEmpty) {
        print('⚠️ Texto vacío, no se puede hablar');
        return;
      }

      print('🗣️ TTS hablando (MOCK): "$text"');
      _isSpeaking = true;
      _isPaused = false;
      
      // Simular duración basada en la longitud del texto
      final duration = Duration(milliseconds: (text.length * 80).clamp(1000, 8000));
      await Future.delayed(duration);
      
      _isSpeaking = false;
      print('✅ TTS: Completado (MOCK)');
      
    } catch (e) {
      print('❌ Error al hablar: $e');
      _isSpeaking = false;
    }
  }

  /// Detiene la reproducción (MOCK)
  Future<void> stop() async {
    try {
      if (_isSpeaking || _isPaused) {
        _isSpeaking = false;
        _isPaused = false;
        print('🛑 TTS: Detenido (MOCK)');
      }
    } catch (e) {
      print('❌ Error deteniendo TTS: $e');
    }
  }

  /// Pausa la reproducción (MOCK)
  Future<void> pause() async {
    try {
      if (_isSpeaking && !_isPaused) {
        _isPaused = true;
        print('⏸️ TTS: Pausado (MOCK)');
      }
    } catch (e) {
      print('❌ Error pausando TTS: $e');
    }
  }

  /// Continúa la reproducción (MOCK)
  Future<void> continue_() async {
    try {
      if (_isPaused) {
        _isPaused = false;
        print('▶️ TTS: Continuando (MOCK)...');
      }
    } catch (e) {
      print('❌ Error continuando TTS: $e');
    }
  }

  /// Configura el idioma (MOCK)
  Future<void> setLanguage(String language) async {
    try {
      print('🌍 TTS idioma configurado (MOCK): $language');
    } catch (e) {
      print('❌ Error configurando idioma TTS: $e');
    }
  }

  /// Configura la velocidad de habla (MOCK)
  Future<void> setSpeechRate(double rate) async {
    try {
      print('⚡ TTS velocidad configurada (MOCK): $rate');
    } catch (e) {
      print('❌ Error configurando velocidad TTS: $e');
    }
  }

  /// Configura el tono de voz (MOCK)
  Future<void> setPitch(double pitch) async {
    try {
      print('🎵 TTS tono configurado (MOCK): $pitch');
    } catch (e) {
      print('❌ Error configurando tono TTS: $e');
    }
  }

  /// Configura el volumen (MOCK)
  Future<void> setVolume(double volume) async {
    try {
      print('🔊 TTS volumen configurado (MOCK): $volume');
    } catch (e) {
      print('❌ Error configurando volumen TTS: $e');
    }
  }

  /// Obtiene los idiomas disponibles (MOCK)
  Future<List<String>> getLanguages() async {
    return ['es-ES', 'en-US', 'fr-FR', 'de-DE', 'it-IT']; // Mock languages
  }

  /// Obtiene las voces disponibles (MOCK)
  Future<List<Map<String, String>>> getVoices() async {
    return [
      {'name': 'Spanish Female Voice', 'locale': 'es-ES'},
      {'name': 'Spanish Male Voice', 'locale': 'es-ES'},
      {'name': 'English Female Voice', 'locale': 'en-US'},
      {'name': 'English Male Voice', 'locale': 'en-US'},
    ]; // Mock voices
  }

  /// Configura la voz específica (MOCK)
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      print('👤 TTS voz configurada (MOCK): ${voice['name']}');
    } catch (e) {
      print('❌ Error configurando voz TTS: $e');
    }
  }

  /// Habla y espera a que termine (MOCK)
  Future<void> speakAndWait(String text) async {
    if (text.trim().isEmpty) return;
    
    await speak(text);
    
    // Esperar hasta que termine de hablar
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Habla un mensaje del sistema con configuración especial (MOCK)
  Future<void> speakSystemMessage(String message) async {
    try {
      // Configuración para mensajes del sistema
      await setSpeechRate(0.7); // Más lento para claridad
      await setPitch(0.9); // Tono ligeramente más bajo
      
      await speakAndWait(message);
      
    } finally {
      // Restaurar configuración
      await setSpeechRate(0.6);
      await setPitch(1.0);
    }
  }

  /// Habla una respuesta de IA con entonación natural (MOCK)
  Future<void> speakAIResponse(String response) async {
    // Configuración para respuestas de IA
    await setSpeechRate(0.6); // Velocidad conversacional
    await setPitch(1.0); // Tono natural
    
    await speakAndWait(response);
  }

  /// Verifica si TTS está disponible (MOCK)
  Future<bool> isAvailable() async {
    return true; // Mock siempre disponible
  }

  /// Limpia recursos (MOCK)
  void dispose() {
    try {
      if (_isSpeaking) {
        _isSpeaking = false;
      }
      _isInitialized = false;
      _isSpeaking = false;
      _isPaused = false;
      print('🗑️ TTSService disposed (MOCK)');
    } catch (e) {
      print('❌ Error disposing TTS: $e');
    }
  }
}