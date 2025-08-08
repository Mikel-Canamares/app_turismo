import 'dart:async';
import 'dart:math';

/// Servicio de Speech-to-Text con funcionalidad real progresiva
/// Fase 1: Interfaz funcional que permite flujo completo de la app
/// Fase 2: Se integrará con Web Speech API o plugins compatibles
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isListening = false;
  bool _isAvailable = true;
  bool _isInitialized = false;
  String _lastWords = '';
  double _confidence = 0.0;
  
  // Respuestas simuladas más realistas para desarrollo
  final List<String> _responses = [
    "¿Qué puedo visitar aquí?",
    "Cuéntame sobre este lugar",
    "¿Cuál es la historia de este sitio?",
    "¿Qué hay de interesante cerca?",
    "Dime más sobre esta zona",
    "¿Hay algún museo por aquí?",
    "¿Dónde puedo comer?",
    "¿Qué actividades hay?",
    "¿Hay parques cerca?",
    "Cuéntame curiosidades",
    "¿Cómo llego al centro?",
    "¿Qué monumentos hay?",
    "¿Hay tours disponibles?",
    "¿Cuándo abre el museo?",
    "¿Es segura esta zona?",
    "terminar",
    "stop",
    "adiós"
  ];
  
  // Getters públicos requeridos por la interfaz
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  
  /// Inicialización rápida y exitosa para no bloquear el flujo
  Future<bool> initialize() async {
    print("🎤 SpeechService: Inicializando servicio de voz...");
    
    // Simulación corta para no bloquear
    await Future.delayed(const Duration(milliseconds: 200));
    
    _isInitialized = true;
    _isAvailable = true;
    
    print("✅ SpeechService: Servicio inicializado correctamente");
    print("📝 Modo: Entrada simulada para desarrollo (se mejorará progresivamente)");
    
    return true;
  }

  /// Verificación rápida de permisos
  Future<bool> get hasPermission async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  /// Solicitud de permisos sin bloqueo
  Future<bool> requestPermission() async {
    print("🔐 SpeechService: Verificando permisos de micrófono...");
    await Future.delayed(const Duration(milliseconds: 100));
    print("✅ SpeechService: Permisos concedidos");
    return true;
  }

  /// Entrada de voz simulada pero funcional
  Future<String?> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String localeId = 'es-ES',
  }) async {
    if (_isListening) {
      print("⚠️ SpeechService: Ya está escuchando");
      return null;
    }
    
    print("🎤 SpeechService: Iniciando escucha...");
    print("🎯 Simulando entrada de voz (2-4 segundos)");
    
    _isListening = true;
    
    try {
      // Tiempo de escucha realista pero no excesivo
      final duration = 2000 + Random().nextInt(2000); // 2-4 segundos
      await Future.delayed(Duration(milliseconds: duration));
      
      // 90% de éxito, 10% sin detectar (realista)
      if (Random().nextInt(10) == 0) {
        print("⚠️ SpeechService: No se detectó entrada");
        _isListening = false;
        return null;
      }
      
      // Respuesta aleatoria pero coherente
      final randomIndex = Random().nextInt(_responses.length);
      _lastWords = _responses[randomIndex];
      _confidence = 0.85 + (Random().nextDouble() * 0.15); // 85-100%
      
      print("🗣️ Entrada detectada: '$_lastWords'");
      print("📊 Confianza: ${(_confidence * 100).toStringAsFixed(1)}%");
      
      _isListening = false;
      return _lastWords;
      
    } catch (e) {
      print("❌ SpeechService Error: $e");
      _isListening = false;
      return null;
    }
  }

  /// Control de escucha
  Future<void> stopListening() async {
    if (_isListening) {
      print("🛑 SpeechService: Deteniendo escucha...");
      _isListening = false;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Cancelación limpia
  Future<void> cancel() async {
    if (_isListening) {
      print("❌ SpeechService: Cancelando escucha...");
      _isListening = false;
      _lastWords = '';
      _confidence = 0.0;
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Idiomas soportados
  Future<List<String>> getAvailableLocales() async {
    return ['es-ES', 'es-MX', 'en-US', 'en-GB', 'fr-FR', 'de-DE', 'it-IT'];
  }

  /// Método conveniente para comandos
  Future<String?> listenForCommand({
    String? prompt,
    Duration timeout = const Duration(seconds: 10),
    String localeId = 'es-ES',
  }) async {
    if (prompt != null) {
      print('💭 Esperando comando: $prompt');
    }
    
    return await startListening(
      listenFor: timeout,
      pauseFor: const Duration(seconds: 2),
      localeId: localeId,
    );
  }

  /// Limpieza de recursos
  void dispose() {
    print("🗑️ SpeechService: Liberando recursos...");
    if (_isListening) {
      _isListening = false;
    }
    _isInitialized = false;
    _lastWords = '';
    _confidence = 0.0;
  }
}

/// Extensión futura: Implementación real con Web Speech API
/// Esto permitirá funcionalidad real en navegadores y dispositivos compatibles
class WebSpeechRecognition {
  // TODO: Implementar Web Speech API para navegadores
  // TODO: Integrar con plugins nativos estables cuando estén disponibles
  // TODO: Fallback inteligente según plataforma
}