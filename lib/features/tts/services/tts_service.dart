import 'dart:async';
import 'dart:math';

/// Servicio de Text-to-Speech con funcionalidad real progresiva
/// Fase 1: Interfaz funcional que simula TTS sin bloquear el flujo
/// Fase 2: Se integrará con Web Speech API o plugins compatibles
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  // Configuración realista
  String _language = 'es-ES';
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;

  // Getters públicos
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  String get language => _language;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;

  /// Inicialización rápida para no bloquear el flujo
  Future<bool> initialize() async {
    print("🔊 TTSService: Inicializando síntesis de voz...");
    
    // Inicialización muy rápida
    await Future.delayed(const Duration(milliseconds: 150));
    
    _isInitialized = true;
    
    print("✅ TTSService: Servicio inicializado");
    print("🌐 Idioma por defecto: $_language");
    print("📝 Modo: Síntesis simulada para desarrollo");
    
    return true;
  }

  /// Síntesis de voz funcional que no bloquea la UI
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('❌ TTSService: No se pudo inicializar');
        return false;
      }
    }

    if (_isSpeaking) {
      print('⚠️ TTSService: Deteniendo reproducción anterior...');
      await stop();
    }

    if (text.trim().isEmpty) {
      print('⚠️ TTSService: Texto vacío');
      return false;
    }

    try {
      final displayText = text.length > 50 ? 
        "${text.substring(0, 47)}..." : text;
      
      print('🔊 TTSService: Reproduciendo: "$displayText"');
      
      _isSpeaking = true;
      
      // Cálculo realista del tiempo de habla
      // Español: ~150 palabras por minuto = ~2.5 palabras por segundo
      final words = text.split(RegExp(r'\s+')).length;
      final baseTime = (words / 2.5 * 1000).round(); // milisegundos
      final adjustedTime = (baseTime / _speechRate).round();
      
      // Añadir variación natural (±200ms)
      final variance = Random().nextInt(400) - 200;
      final finalDuration = Duration(
        milliseconds: (adjustedTime + variance).clamp(500, 10000)
      );
      
      print('⏱️ TTSService: Duración estimada: ${finalDuration.inSeconds}s');
      
      // Simular reproducción
      await Future.delayed(finalDuration);
      
      _isSpeaking = false;
      print('✅ TTSService: Reproducción completada');
      
      return true;
      
    } catch (e) {
      print('❌ TTSService Error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Control de reproducción
  Future<void> stop() async {
    if (_isSpeaking) {
      print('🛑 TTSService: Deteniendo reproducción...');
      _isSpeaking = false;
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      print('⏸️ TTSService: Pausando...');
      // En simulación, pausa = stop
      await stop();
    }
  }

  Future<void> resume() async {
    print('▶️ TTSService: Resume no implementado en modo simulación');
  }

  /// Configuración de parámetros
  Future<void> setLanguage(String language) async {
    _language = language;
    print('🌐 TTSService: Idioma cambiado a $language');
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    print('⚡ TTSService: Velocidad: $_speechRate');
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    print('🔊 TTSService: Volumen: $_volume');
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    print('🎵 TTSService: Tono: $_pitch');
  }

  /// Capacidades del servicio
  Future<List<String>> getAvailableLanguages() async {
    return [
      'es-ES', 'es-MX', 'es-AR', 'es-CL', 'es-CO',
      'en-US', 'en-GB', 'en-AU',
      'fr-FR', 'de-DE', 'it-IT', 'pt-BR'
    ];
  }

  Future<List<String>> getAvailableVoices() async {
    return [
      'María (España)', 'Carlos (México)', 'Ana (Argentina)',
      'Luis (Colombia)', 'Sofia (Chile)', 'Diego (Perú)'
    ];
  }

  Future<bool> isLanguageAvailable(String language) async {
    final available = await getAvailableLanguages();
    return available.contains(language);
  }

  /// Método con configuración personalizada
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
      if (language != null) await setLanguage(language);
      if (speechRate != null) await setSpeechRate(speechRate);
      if (volume != null) await setVolume(volume);
      if (pitch != null) await setPitch(pitch);

      // Hablar
      return await speak(text);
    } finally {
      // Restaurar configuración
      await setLanguage(originalLanguage);
      await setSpeechRate(originalRate);
      await setVolume(originalVolume);
      await setPitch(originalPitch);
    }
  }

  /// Limpieza de recursos
  void dispose() {
    print("🗑️ TTSService: Liberando recursos...");
    if (_isSpeaking) {
      _isSpeaking = false;
    }
    _isInitialized = false;
  }
}

/// Extensión futura: Implementación real
class WebSpeechSynthesis {
  // TODO: Implementar Web Speech Synthesis API
  // TODO: Integrar con plugins nativos estables
  // TODO: Soporte para voces premium
}