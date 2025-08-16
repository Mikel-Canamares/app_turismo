import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio de Speech-to-Text usando grabación + Whisper API de OpenAI
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  late AudioRecorder _audioRecorder;
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentRecordingPath = '';
  
  // Control de estado para "mantener presionado"
  Completer<String?>? _listeningCompleter;
  bool _hasPermission = false;

  // Cliente HTTP para Whisper API
  late Dio _dio;

  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  Future<bool> get hasPermission async {
    if (!_isInitialized) await initialize();
    return _hasPermission;
  }

  /// Inicializa el servicio de grabación
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      print('🎤 Inicializando SpeechService con Whisper API...');
      
      _audioRecorder = AudioRecorder();
      _dio = Dio();
      
      // Verificar permisos de grabación
      _hasPermission = await _audioRecorder.hasPermission();
      
      _isInitialized = true;
      print('✅ SpeechService con Whisper inicializado correctamente');
      print('🔐 Permisos de grabación: ${_hasPermission ? "Otorgados" : "Denegados"}');
      
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
      if (!_hasPermission) {
        print('🔐 Solicitando permisos de micrófono...');
        _hasPermission = await _audioRecorder.hasPermission();
        
        if (!_hasPermission) {
          print('❌ Permisos de micrófono denegados');
          return false;
        }
      }
      
      print('✅ Permisos de micrófono otorgados');
      return true;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Inicia grabación (PARA MANTENER PRESIONADO)
  Future<String?> startListeningPressed() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    if (_isListening) {
      print('⚠️ Ya está grabando');
      return null;
    }

    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    try {
      print('🎤 Iniciando grabación de audio...');
      
      // Crear archivo temporal para la grabación
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/speech_$timestamp.m4a';
      
      _listeningCompleter = Completer<String?>();
      _isListening = true;

      // Configurar y iniciar grabación en M4A (compatible con Whisper)
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // M4A/AAC
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath,
      );

      print('🔴 Grabando audio... (mantén presionado)');
      return await _listeningCompleter!.future;
      
    } catch (e) {
      print('❌ Error iniciando grabación: $e');
      _isListening = false;
      _listeningCompleter?.complete(null);
      return null;
    }
  }

  /// Detiene grabación y transcribe con Whisper (AL SOLTAR EL BOTÓN)
  Future<String?> stopListening() async {
    if (!_isListening) return null;

    try {
      print('🛑 Deteniendo grabación...');
      
      // Detener grabación
      final path = await _audioRecorder.stop();
      _isListening = false;
      
      if (path == null || path.isEmpty) {
        print('⚠️ No se grabó audio');
        _listeningCompleter?.complete(null);
        return null;
      }
      
      print('🎵 Audio grabado en: $path');
      
      // Transcribir con Whisper API
      final transcription = await _transcribeWithWhisper(path);
      
      // Limpiar archivo temporal
      try {
        await File(path).delete();
        print('🗑️ Archivo temporal eliminado');
      } catch (e) {
        print('⚠️ No se pudo eliminar archivo temporal: $e');
      }
      
      _listeningCompleter?.complete(transcription);
      
      if (transcription != null && transcription.isNotEmpty) {
        print('✅ Texto transcrito: "$transcription"');
      } else {
        print('⚠️ No se transcribió texto');
      }
      
      return transcription;
    } catch (e) {
      print('❌ Error deteniendo grabación: $e');
      _listeningCompleter?.complete(null);
      return null;
    }
  }

  /// Cancela la grabación
  Future<void> cancel() async {
    if (!_isListening) return;
    
    try {
      print('❌ Cancelando grabación...');
      await _audioRecorder.stop();
      _isListening = false;
      _listeningCompleter?.complete(null);
      
      // Limpiar archivo si existe
      if (_currentRecordingPath.isNotEmpty && File(_currentRecordingPath).existsSync()) {
        await File(_currentRecordingPath).delete();
      }
    } catch (e) {
      print('❌ Error cancelando grabación: $e');
    }
  }

  /// Transcribe audio usando Whisper API de OpenAI
  Future<String?> _transcribeWithWhisper(String audioPath) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ OPENAI_API_KEY no configurada');
        return null;
      }

      print('🤖 Transcribiendo con Whisper API...');
      
      final audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        print('❌ Archivo de audio no existe: $audioPath');
        return null;
      }

      // Verificar tamaño del archivo
      final fileSize = audioFile.lengthSync();
      print('📊 Tamaño del archivo: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      if (fileSize < 1024) { // Menos de 1KB, probablemente vacío
        print('⚠️ Archivo de audio muy pequeño, probablemente sin contenido');
        return null;
      }

      // Crear FormData para la API
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioPath,
          filename: 'audio.m4a',
        ),
        'model': 'whisper-1',
        'language': 'es', // Español
        'response_format': 'text',
      });

      final response = await _dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'multipart/form-data',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final transcription = response.data.toString().trim();
        print('✅ Transcripción exitosa: "$transcription"');
        return transcription.isNotEmpty ? transcription : null;
      } else {
        print('❌ Error en Whisper API: ${response.statusCode} - ${response.data}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error transcribiendo con Whisper: $e');
      return null;
    }
  }

  /// Obtiene formatos de audio soportados (simulado)
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

  /// Verifica si está disponible la transcripción
  bool get isAvailable => _isInitialized && _hasPermission;
}