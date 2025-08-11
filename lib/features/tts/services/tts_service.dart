import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de Text-to-Speech REAL usando flutter_tts plugin
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  String _language = 'es-ES';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  /// Inicializa el servicio de TTS
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('🔊 Inicializando TTSService...');
      _flutterTts = FlutterTts();

      // Configurar callbacks
      _flutterTts.setStartHandler(() {
        print('🗣️ TTS iniciado');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('✅ TTS completado');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ Error TTS: $msg');
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        print('🛑 TTS cancelado');
        _isSpeaking = false;
      });

      _flutterTts.setPauseHandler(() {
        print('⏸️ TTS pausado');
      });

      _flutterTts.setContinueHandler(() {
        print('▶️ TTS reanudado');
      });

      // Configuración inicial
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      _isInitialized = true;
      print('✅ TTSService inicializado correctamente');
      
      return true;
    } catch (e) {
      print('❌ Error inicializando TTSService: $e');
      return false;
    }
  }

  /// Reproduce texto con voz
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) {
      print('⚠️ TTSService: Texto vacío');
      return false;
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      final displayText = text.length > 50 ? 
        "${text.substring(0, 47)}..." : text;
      
      print('🔊 TTSService: Reproduciendo: "$displayText"');
      
      // Detener cualquier reproducción anterior
      if (_isSpeaking) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _isSpeaking = true;
      final result = await _flutterTts.speak(text);
      
      if (result == 1) {
        print('✅ TTSService: Reproducción iniciada correctamente');
        return true;
      } else {
        print('❌ TTSService: Error iniciando reproducción');
        _isSpeaking = false;
        return false;
      }
      
    } catch (e) {
      print('❌ TTSService: Error en speak: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      print('🛑 TTSService: Deteniendo reproducción...');
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('❌ TTSService: Error deteniendo: $e');
    }
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;
    
    try {
      print('⏸️ TTSService: Pausando...');
      await _flutterTts.pause();
    } catch (e) {
      print('❌ TTSService: Error pausando: $e');
    }
  }

  /// Configura el idioma
  Future<bool> setLanguage(String language) async {
    if (!_isInitialized) await initialize();
    
    try {
      print('🌍 TTSService: Configurando idioma: $language');
      final result = await _flutterTts.setLanguage(language);
      if (result == 1) {
        _language = language;
        print('✅ TTSService: Idioma configurado');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ TTSService: Error configurando idioma: $e');
      return false;
    }
  }

  /// Configura velocidad de habla
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
      _speechRate = rate.clamp(0.0, 1.0);
      print('🏃 TTSService: Velocidad configurada: $_speechRate');
    } catch (e) {
      print('❌ TTSService: Error configurando velocidad: $e');
    }
  }

  /// Configura volumen
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
      _volume = volume.clamp(0.0, 1.0);
      print('🔊 TTSService: Volumen configurado: $_volume');
    } catch (e) {
      print('❌ TTSService: Error configurando volumen: $e');
    }
  }

  /// Configura tono
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
      _pitch = pitch.clamp(0.5, 2.0);
      print('🎵 TTSService: Tono configurado: $_pitch');
    } catch (e) {
      print('❌ TTSService: Error configurando tono: $e');
    }
  }

  /// Obtiene idiomas disponibles
  Future<List<String>> getLanguages() async {
    if (!_isInitialized) await initialize();
    
    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null) {
        final languageList = List<String>.from(languages);
        print('🌍 TTSService: Idiomas disponibles: ${languageList.take(5).join(', ')}...');
        return languageList;
      }
      return [];
    } catch (e) {
      print('❌ TTSService: Error obteniendo idiomas: $e');
      return [];
    }
  }

  /// Obtiene voces disponibles
  Future<List<Map<String, String>>> getVoices() async {
    if (!_isInitialized) await initialize();
    
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        final voiceList = List<Map<String, String>>.from(
          voices.map((voice) => Map<String, String>.from(voice))
        );
        print('🎤 TTSService: Voces disponibles: ${voiceList.length}');
        return voiceList;
      }
      return [];
    } catch (e) {
      print('❌ TTSService: Error obteniendo voces: $e');
      return [];
    }
  }

  /// Reproduce y espera a que termine
  Future<bool> speakAndWait(String text) async {
    if (!await speak(text)) return false;
    
    // Esperar hasta que termine de hablar
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return true;
  }

  /// Mensajes específicos del sistema
  Future<void> speakSystemMessage(String message) async {
    print('📢 TTSService: Mensaje del sistema: "$message"');
    await speak(message);
  }

  /// Respuestas de la IA
  Future<void> speakAIResponse(String response) async {
    print('🤖 TTSService: Respuesta IA: "${response.length > 50 ? response.substring(0, 50) + '...' : response}"');
    await speak(response);
  }
}