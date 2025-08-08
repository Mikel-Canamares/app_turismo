import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/permissions/services/permission_service.dart';
import '../../features/location/services/location_service.dart';
import '../../features/speech/services/speech_service.dart';
import '../../features/tts/services/tts_service.dart';
import '../../features/poi/services/poi_service.dart';
import '../../features/ai_chat/services/ai_service.dart';
import '../../features/poi/models/poi_model.dart';
import '../utils/constants.dart';

enum AppState {
  initializing,
  requestingPermissions,
  gettingLocation,
  findingPOIs,
  ready,
  listening,
  processing,
  speaking,
  error,
}

class AppOrchestrator {
  static final AppOrchestrator _instance = AppOrchestrator._internal();
  factory AppOrchestrator() => _instance;
  AppOrchestrator._internal();

  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final SpeechService _speechService = SpeechService();
  final TTSService _ttsService = TTSService();
  final POIService _poiService = POIService();
  final AIService _aiService = AIService();

  AppState _currentState = AppState.initializing;
  Position? _currentPosition;
  PointOfInterest? _currentPOI;
  String? _currentContext;

  AppState get currentState => _currentState;
  Position? get currentPosition => _currentPosition;
  PointOfInterest? get currentPOI => _currentPOI;

  // Callback para notificar cambios de estado
  Function(AppState)? onStateChanged;

  Future<void> initializeApp() async {
    _updateState(AppState.initializing);

    try {
      // 1. Inicializar servicios
      await _ttsService.initialize();
      await _speechService.initialize();

      // 2. Solicitar permisos
      _updateState(AppState.requestingPermissions);
      final permissionsGranted = await _permissionService.requestAllPermissions();
      
      if (!permissionsGranted) {
        await _ttsService.speak(AppConstants.locationPermissionDenied);
        _updateState(AppState.error);
        return;
      }

      // 3. Obtener ubicación
      _updateState(AppState.gettingLocation);
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition == null) {
        await _ttsService.speak(AppConstants.noLocationMessage);
        _updateState(AppState.error);
        return;
      }

      // 4. Buscar POIs
      _updateState(AppState.findingPOIs);
      _currentPOI = await _poiService.findMostInterestingNearbyPOI(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // 5. Crear contexto para la IA
      if (_currentPOI != null) {
        _currentContext = _poiService.createPOIContext(
          _currentPOI!,
          userLat: _currentPosition!.latitude,
          userLon: _currentPosition!.longitude,
        );
      }

      // 6. Dar bienvenida
      _updateState(AppState.speaking);
      final welcomeMessage = await _aiService.generateWelcomeMessage(_currentContext);
      await _ttsService.speakAndWait(welcomeMessage);

      // 7. Iniciar bucle de conversación
      _updateState(AppState.ready);
      _startConversationLoop();

    } catch (e) {
      print('Error inicializando app: $e');
      await _ttsService.speak(AppConstants.errorMessage);
      _updateState(AppState.error);
    }
  }

  Future<void> _startConversationLoop() async {
    while (_currentState != AppState.error) {
      try {
        // Escuchar comando del usuario
        _updateState(AppState.listening);
        final userInput = await _speechService.listenForCommand(
          prompt: 'Esperando tu pregunta...',
        );

        if (userInput == null || userInput.trim().isEmpty) {
          // Si no se escuchó nada, seguir esperando
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        // Procesar con IA
        _updateState(AppState.processing);
        String? response;

        if (_currentContext != null) {
          response = await _aiService.generateTourismResponse(
            question: userInput,
            locationContext: _currentContext!,
          );
        } else {
          response = await _aiService.generateResponse(
            userMessage: userInput,
            context: 'El usuario está pidiendo información turística general.',
          );
        }

        if (response == null) {
          response = AppConstants.errorMessage;
        }

        // Responder por voz
        _updateState(AppState.speaking);
        await _ttsService.speakAndWait(response);

        // Volver a estar listo para la siguiente pregunta
        _updateState(AppState.ready);
        
        // Pequeña pausa antes de empezar a escuchar de nuevo
        await Future.delayed(const Duration(seconds: 1));

      } catch (e) {
        print('Error en bucle de conversación: $e');
        await _ttsService.speak('Hubo un problema, pero sigamos. ¿Qué más te gustaría saber?');
        _updateState(AppState.ready);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _updateState(AppState newState) {
    _currentState = newState;
    onStateChanged?.call(newState);
    print('Estado cambiado a: $newState');
  }

  // Método para reiniciar la aplicación
  Future<void> restartApp() async {
    await _speechService.stopListening();
    await _ttsService.stop();
    await initializeApp();
  }

  // Método para detener la aplicación
  Future<void> stopApp() async {
    await _speechService.stopListening();
    await _ttsService.stop();
    _updateState(AppState.error);
  }

  // Método para cambiar de ubicación manualmente
  Future<void> updateLocation() async {
    _updateState(AppState.gettingLocation);
    
    _currentPosition = await _locationService.getCurrentLocation();
    
    if (_currentPosition != null) {
      _updateState(AppState.findingPOIs);
      _currentPOI = await _poiService.findMostInterestingNearbyPOI(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (_currentPOI != null) {
        _currentContext = _poiService.createPOIContext(
          _currentPOI!,
          userLat: _currentPosition!.latitude,
          userLon: _currentPosition!.longitude,
        );

        await _ttsService.speak(
          'He actualizado tu ubicación. Ahora estás cerca de ${_currentPOI!.name}. ¿Qué te gustaría saber?'
        );
      } else {
        await _ttsService.speak(AppConstants.noPlacesFoundMessage);
      }
    } else {
      await _ttsService.speak(AppConstants.noLocationMessage);
    }
    
    _updateState(AppState.ready);
  }

  void dispose() {
    _speechService.stopListening();
    _ttsService.dispose();
  }
}
