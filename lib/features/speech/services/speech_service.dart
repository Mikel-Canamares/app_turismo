// Mock implementation of speech service for compilation
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  bool _isInitialized = false;
  bool _isListening = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    try {
      // Mock initialization
      _isInitialized = true;
      print('Speech service initialized (mock)');
      return _isInitialized;
    } catch (e) {
      print('Error inicializando speech to text: $e');
      return false;
    }
  }

  Future<String?> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      return null;
    }

    try {
      // Mock listening - simulate user input
      _isListening = true;
      print('Mock: Iniciando escucha...');
      
      await Future.delayed(const Duration(seconds: 3));
      
      _isListening = false;
      
      // Return a mock response for demonstration
      const mockResponses = [
        "¿Qué puedo visitar aquí?",
        "Cuéntame sobre este lugar",
        "¿Cuál es la historia de este sitio?",
        "¿Qué hay de interesante cerca?",
        "Dime más sobre esta zona"
      ];
      
      final response = mockResponses[DateTime.now().second % mockResponses.length];
      print('Mock texto reconocido: $response');
      return response;
    } catch (e) {
      print('Error durante el reconocimiento de voz: $e');
      return null;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      print('Mock: Deteniendo escucha');
    }
  }

  Future<void> cancel() async {
    if (_isListening) {
      _isListening = false;
      print('Mock: Cancelando escucha');
    }
  }

  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return ['es_ES', 'en_US'];
  }

  Future<bool> get hasPermission async => true; // Mock permission

  Future<bool> requestPermission() async {
    return true; // Mock permission granted
  }

  // Método para escuchar continuamente
  Future<String?> listenForCommand({
    String? prompt,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      print('Iniciando escucha para comando${prompt != null ? ': $prompt' : ''}');
      
      final result = await startListening(
        listenFor: timeout,
        pauseFor: const Duration(seconds: 2),
      );
      
      if (result != null && result.trim().isNotEmpty) {
        print('Comando recibido: $result');
        return result.trim();
      }
      
      return null;
    } catch (e) {
      print('Error escuchando comando: $e');
      return null;
    }
  }
}
