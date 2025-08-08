import 'dart:async';
import 'dart:math';

/// Mock implementation mejorado de TTSService
/// Simula el comportamiento real del Text-to-Speech
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Configuración por defecto
  String _language = 'es-ES';
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  String get language => _language;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;

  Future<bool> initialize() async {
    print("🔊 [MOCK] TTSService: Inicializando...");
    await Future.delayed(const Duration(milliseconds: 400));
    
    _isInitialized = true;
    print("✅ [MOCK] TTSService: Inicializado correctamente con idioma $_language");
    print("🌐 [MOCK] Idiomas TTS disponibles: es-ES, es-US, en-US, fr-FR, de-DE");
    
    return true;
  }

  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('❌ [MOCK] No se puede reproducir: TTS no inicializado');
        return false;
      }
    }

    if (_isSpeaking) {
      print('⚠️ [MOCK] TTSService: Ya se está reproduciendo, deteniendo anterior...');
      await stop();
    }

    if (text.trim().isEmpty) {
      print('⚠️ [MOCK] TTSService: Texto vacío, no se puede reproducir');
      return false;
    }

    try {
      print('🔊 [MOCK] TTSService: Reproduciendo: "${text.substring(0, text.length.clamp(0, 50))}${text.length > 50 ? '...' : ''}"');
      
      _isSpeaking = true;
      
      // Simular tiempo de reproducción basado en longitud del texto
      // Aproximadamente 150 palabras por minuto en español
      final words = text.split(' ').length;
      final estimatedDuration = Duration(milliseconds: (words * 400 / _speechRate).round());
      final actualDuration = Duration(
        milliseconds: estimatedDuration.inMilliseconds + Random().nextInt(500) - 250
      );
      
      print('⏱️ [MOCK] Duración estimada: ${actualDuration.inSeconds} segundos');
      
      await Future.delayed(actualDuration);
      
      _isSpeaking = false;
      print('✅ [MOCK] TTSService: Reproducción completada');
      return true;
      
    } catch (e) {
      print('❌ [MOCK] TTSService Error reproduciendo: $e');
      _isSpeaking = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      print('🛑 [MOCK] TTSService: Deteniendo reproducción...');
      _isSpeaking = false;
      print('✅ [MOCK] TTSService: Reproducción detenida');
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      print('⏸️ [MOCK] TTSService: Pausando reproducción...');
      // En el mock, pausa = stop
      _isSpeaking = false;
      print('✅ [MOCK] TTSService: Reproducción pausada');
    }
  }

  Future<void> resume() async {
    print('▶️ [MOCK] TTSService: Función resume no implementada en mock');
  }

  // Configuración de parámetros
  Future<void> setLanguage(String language) async {
    _language = language;
    print('🌐 [MOCK] TTSService: Idioma cambiado a $language');
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    print('⚡ [MOCK] TTSService: Velocidad cambiada a $_speechRate');
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    print('🔊 [MOCK] TTSService: Volumen cambiado a $_volume');
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    print('🎵 [MOCK] TTSService: Tono cambiado a $_pitch');
  }

  Future<List<String>> getAvailableLanguages() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ['es-ES', 'es-US', 'en-US', 'fr-FR', 'de-DE', 'it-IT'];
  }

  Future<List<String>> getAvailableVoices() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ['María (España)', 'Carlos (México)', 'Ana (Argentina)', 'Luis (Colombia)'];
  }

  Future<bool> isLanguageAvailable(String language) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final availableLanguages = await getAvailableLanguages();
    return availableLanguages.contains(language);
  }

  /// Método conveniente para hablar con configuración específica
  Future<bool> speakWithConfig({
    required String text,
    String? language,
    double? speechRate,
    double? volume,
    double? pitch,
  }) async {
    // Guardar configuración actual
    final originalLanguage = _language;
    final originalRate = _speechRate;
    final originalVolume = _volume;
    final originalPitch = _pitch;

    try {
      // Aplicar configuración temporal
      if (language != null && language != _language) {
        await setLanguage(language);
      }
      if (speechRate != null && speechRate != _speechRate) {
        await setSpeechRate(speechRate);
      }
      if (volume != null && volume != _volume) {
        await setVolume(volume);
      }
      if (pitch != null && pitch != _pitch) {
        await setPitch(pitch);
      }

      // Hablar
      final result = await speak(text);

      return result;
    } finally {
      // Restaurar configuración original
      if (language != null && language != originalLanguage) {
        await setLanguage(originalLanguage);
      }
      if (speechRate != null && speechRate != originalRate) {
        await setSpeechRate(originalRate);
      }
      if (volume != null && volume != originalVolume) {
        await setVolume(originalVolume);
      }
      if (pitch != null && pitch != originalPitch) {
        await setPitch(originalPitch);
      }
    }
  }

  void dispose() {
    print("🗑️ [MOCK] TTSService disposed");
    if (_isSpeaking) {
      _isSpeaking = false;
    }
    _isInitialized = false;
  }
}