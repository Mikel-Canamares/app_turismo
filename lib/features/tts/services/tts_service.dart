// Mock implementation of TTS service for compilation
import '../../../core/utils/constants.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    try {
      // Mock initialization
      _isInitialized = true;
      print('TTS inicializado correctamente (mock)');
    } catch (e) {
      print('Error inicializando TTS: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      print('TTS no inicializado, no se puede hablar');
      return;
    }

    try {
      // Detener cualquier reproducción anterior
      if (_isSpeaking) {
        await stop();
      }

      print('TTS hablando (mock): $text');
      _isSpeaking = true;
      
      // Simulate speaking duration based on text length
      final duration = Duration(milliseconds: (text.length * 50).clamp(1000, 5000));
      await Future.delayed(duration);
      
      _isSpeaking = false;
      print('TTS: Completado (mock)');
    } catch (e) {
      print('Error al hablar: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      _isSpeaking = false;
      print('TTS: Detenido (mock)');
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      print('TTS: Pausado (mock)');
    }
  }

  Future<List<dynamic>> getLanguages() async {
    return ['es-ES', 'en-US'];
  }

  Future<List<dynamic>> getVoices() async {
    return ['Spanish Voice', 'English Voice'];
  }

  Future<void> setLanguage(String language) async {
    print('TTS: Idioma configurado a $language (mock)');
  }

  Future<void> setSpeechRate(double rate) async {
    print('TTS: Velocidad configurada a $rate (mock)');
  }

  Future<void> setVolume(double volume) async {
    print('TTS: Volumen configurado a $volume (mock)');
  }

  Future<void> setPitch(double pitch) async {
    print('TTS: Tono configurado a $pitch (mock)');
  }

  // Método para hablar y esperar a que termine
  Future<void> speakAndWait(String text) async {
    await speak(text);
    
    // Esperar hasta que termine de hablar
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Método para hablar mensajes del sistema con tono amigable
  Future<void> speakSystemMessage(String message) async {
    await speak(message);
  }

  // Método para hablar respuestas de IA
  Future<void> speakAIResponse(String response) async {
    await speak(response);
  }

  void dispose() {
    _isSpeaking = false;
    print('TTS: Disposed (mock)');
  }
}
