import 'dart:async';
import 'dart:math';

/// Servicio de Speech-to-Text HÍBRIDO (funcional para desarrollo)
/// Simula comportamiento real de voz pero permite entrada de texto como fallback
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLocale = 'es_ES';
  String _lastRecognizedWords = '';
  
  // Control de estado para "mantener presionado"
  Completer<String?>? _listeningCompleter;
  bool _hasPermission = true; // Simulamos que tenemos permisos

  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  Future<bool> get hasPermission async => _hasPermission;

  /// Inicializa el servicio de speech-to-text
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      print('🎤 Inicializando SpeechService híbrido...');
      
      // Simular inicialización
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isInitialized = true;
      print('✅ SpeechService híbrido inicializado correctamente');
      return true;
      
    } catch (e) {
      print('❌ Error inicializando SpeechService: $e');
      return false;
    }
  }

  /// Solicita permisos de micrófono
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    try {
      print('🔐 Simulando solicitud de permisos de micrófono...');
      await Future.delayed(const Duration(milliseconds: 300));
      _hasPermission = true;
      print('✅ Permisos otorgados (simulado)');
      return true;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Inicia escucha (PARA MANTENER PRESIONADO)
  Future<String?> startListeningPressed() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    if (_isListening) {
      print('⚠️ Ya está escuchando');
      return null;
    }

    try {
      print('🎤 Iniciando escucha híbrida (mantener presionado)...');
      
      _listeningCompleter = Completer<String?>();
      _lastRecognizedWords = '';
      _isListening = true;

      print('👂 Escuchando... (mantén presionado o usa entrada de texto)');
      
      // En lugar de speech real, esperamos a que se llame stopListening
      return await _listeningCompleter!.future;
      
    } catch (e) {
      print('❌ Error iniciando escucha: $e');
      _isListening = false;
      _listeningCompleter?.complete(null);
      return null;
    }
  }

  /// Detiene escucha (AL SOLTAR EL BOTÓN)
  Future<String?> stopListening() async {
    if (!_isListening) return _lastRecognizedWords.isNotEmpty ? _lastRecognizedWords : null;

    try {
      print('🛑 Deteniendo escucha híbrida...');
      
      _isListening = false;
      
      // Simular reconocimiento de voz con frases de ejemplo
      final result = _generateSimulatedSpeech();
      _lastRecognizedWords = result;
      
      _listeningCompleter?.complete(result);
      
      if (result.isNotEmpty) {
        print('✅ Texto simulado generado: "$result"');
      } else {
        print('⚠️ No se generó texto');
      }
      
      return result;
    } catch (e) {
      print('❌ Error deteniendo escucha: $e');
      _listeningCompleter?.complete(null);
      return null;
    }
  }

  /// Cancela la escucha
  Future<void> cancel() async {
    if (!_isListening) return;
    
    try {
      print('❌ Cancelando escucha híbrida...');
      _isListening = false;
      _listeningCompleter?.complete(null);
    } catch (e) {
      print('❌ Error cancelando escucha: $e');
    }
  }

  /// Genera texto simulado de speech (para desarrollo)
  String _generateSimulatedSpeech() {
    final random = Random();
    final questions = [
      "¿Qué puedo visitar aquí?",
      "Cuéntame sobre este lugar",
      "¿Cuál es la historia de este sitio?",
      "¿Qué hay de interesante cerca?",
      "Dime más sobre esta zona",
      "¿Hay algún museo por aquí?",
      "¿Dónde puedo comer?",
      "¿Qué actividades hay?",
      "¿Hay parques cerca?",
      "Cuéntame curiosidades del lugar",
      "¿Cómo llego al centro?",
      "¿Qué monumentos hay?",
      "¿Hay iglesias históricas?",
      "¿Dónde está la oficina de turismo?",
      "¿Qué eventos hay hoy?",
    ];
    
    // 90% probabilidad de generar una pregunta válida
    if (random.nextDouble() < 0.9) {
      return questions[random.nextInt(questions.length)];
    } else {
      return ""; // Simular que no se escuchó nada
    }
  }

  /// Obtiene idiomas disponibles (simulado)
  Future<List<dynamic>> getAvailableLocales() async {
    return [
      {'localeId': 'es_ES', 'name': 'Español (España)'},
      {'localeId': 'es_MX', 'name': 'Español (México)'},
      {'localeId': 'en_US', 'name': 'English (US)'},
    ];
  }

  /// Método de compatibilidad para startListening
  Future<String?> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    return await startListeningPressed();
  }

  /// Método para inyección manual de texto (para testing)
  void injectText(String text) {
    if (_isListening && _listeningCompleter != null && !_listeningCompleter!.isCompleted) {
      _lastRecognizedWords = text;
      _isListening = false;
      _listeningCompleter!.complete(text);
      print('💉 Texto inyectado: "$text"');
    }
  }
}