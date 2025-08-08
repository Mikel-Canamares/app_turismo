import 'dart:async';
import 'dart:math';

/// Mock implementation mejorado de SpeechService
/// Simula el comportamiento real del reconocimiento de voz
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isListening = false;
  bool _isAvailable = true;
  bool _isInitialized = false;
  String _lastWords = '';
  double _confidence = 0.0;
  
  // Respuestas mock más variadas y realistas
  final List<String> _mockResponses = [
    "¿Qué puedo visitar aquí?",
    "Cuéntame sobre este lugar",
    "¿Cuál es la historia de este sitio?",
    "¿Qué hay de interesante cerca?",
    "Dime más sobre esta zona",
    "¿Hay algún museo por aquí?",
    "¿Dónde puedo comer algo bueno?",
    "¿Qué actividades puedo hacer?",
    "¿Hay algún parque cerca?",
    "Cuéntame curiosidades del lugar",
    "¿Cómo llego al centro histórico?",
    "¿Qué monumentos hay cerca?",
    "¿Hay tours disponibles?",
    "¿Cuándo cierra el museo?",
    "¿Es segura esta zona?",
    "terminar",
    "stop",
    "adiós"
  ];
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  
  Future<bool> initialize() async {
    print("🎤 [MOCK] SpeechService: Inicializando...");
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
    _isAvailable = true;
    print("✅ [MOCK] SpeechService: Inicializado correctamente");
    return true;
  }

  Future<bool> get hasPermission async {
    print("🎤 [MOCK] SpeechService: Verificando permisos...");
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<bool> requestPermission() async {
    print("🎤 [MOCK] SpeechService: Solicitando permisos...");
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<String?> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String localeId = 'es-ES',
  }) async {
    if (_isListening) {
      print("⚠️ [MOCK] SpeechService: Ya está escuchando");
      return null;
    }
    
    print("🎤 [MOCK] SpeechService: Iniciando escucha...");
    _isListening = true;
    
    try {
      // Simular tiempo de escucha realista (2-6 segundos)
      final listeningTime = 2000 + Random().nextInt(4000);
      await Future.delayed(Duration(milliseconds: listeningTime));
      
      // Simular que a veces no se detecta nada (10% de las veces)
      if (Random().nextInt(10) == 0) {
        print("⚠️ [MOCK] SpeechService: No se detectó audio");
        _isListening = false;
        return null;
      }
      
      // Elegir una respuesta mock aleatoria
      final randomIndex = Random().nextInt(_mockResponses.length);
      _lastWords = _mockResponses[randomIndex];
      _confidence = 0.8 + (Random().nextDouble() * 0.2); // 0.8-1.0
      
      print("🎤 [MOCK] Texto reconocido: '$_lastWords' (confianza: ${(_confidence * 100).toStringAsFixed(1)}%)");
      
      _isListening = false;
      return _lastWords;
      
    } catch (e) {
      print("❌ [MOCK] SpeechService Error: $e");
      _isListening = false;
      return null;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      print("🛑 [MOCK] SpeechService: Deteniendo escucha...");
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    if (_isListening) {
      print("❌ [MOCK] SpeechService: Cancelando escucha...");
      _isListening = false;
      _lastWords = '';
      _confidence = 0.0;
    }
  }

  /// Obtiene los idiomas disponibles (mock)
  Future<List<String>> getAvailableLocales() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ['es-ES', 'es-US', 'en-US', 'fr-FR', 'de-DE', 'it-IT'];
  }

  /// Método conveniente para escuchar un comando específico
  Future<String?> listenForCommand({
    String? prompt,
    Duration timeout = const Duration(seconds: 15),
    String localeId = 'es_ES',
  }) async {
    if (prompt != null) {
      print('💭 [MOCK] Esperando comando: $prompt');
    }
    
    return await startListening(
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
    );
  }

  void dispose() {
    print("🗑️ [MOCK] SpeechService disposed");
    if (_isListening) {
      _isListening = false;
    }
    _isInitialized = false;
    _lastWords = '';
    _confidence = 0.0;
  }
}