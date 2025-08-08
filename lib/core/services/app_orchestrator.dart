import 'package:geolocator/geolocator.dart';
import '../../features/permissions/services/permission_service.dart';
import '../../features/location/services/location_service.dart';
import '../../features/poi/services/poi_service.dart';
import '../../features/poi/models/poi_model.dart';
import '../../features/speech/services/speech_service.dart';
import '../../features/tts/services/tts_service.dart';
import '../../features/ai_chat/services/ai_service.dart';

enum AppState {
  initializing,
  requestingPermissions,
  gettingLocation,
  findingPOIs,
  ready,
  listening,
  processing,
  speaking,
  conversationActive,
  error,
}

class AppOrchestrator {
  static final AppOrchestrator _instance = AppOrchestrator._internal();
  factory AppOrchestrator() => _instance;
  AppOrchestrator._internal();

  // Services
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final POIService _poiService = POIService();
  final SpeechService _speechService = SpeechService();
  final TTSService _ttsService = TTSService();
  final AIService _aiService = AIService();

  // Estado
  AppState _currentState = AppState.initializing;
  Position? _currentPosition;
  PointOfInterest? _currentPOI;
  List<PointOfInterest> _nearbyPOIs = [];
  String? _currentContext;
  String? _lastError;
  bool _isRunning = false;
  bool _isInConversation = false;
  bool _shouldContinueListening = false;

  // Getters
  AppState get currentState => _currentState;
  Position? get currentPosition => _currentPosition;
  PointOfInterest? get currentPOI => _currentPOI;
  List<PointOfInterest> get nearbyPOIs => _nearbyPOIs;
  String? get currentContext => _currentContext;
  String? get lastError => _lastError;
  bool get isRunning => _isRunning;
  bool get isInConversation => _isInConversation;

  // Callback para cambios de estado
  Function(AppState)? onStateChanged;
  Function(String)? onError;
  Function(String)? onStatusUpdate;

  /// Inicializa la aplicación completa
  Future<void> initializeApp() async {
    try {
      print('🚀 Iniciando Turismo AI...');
      _isRunning = true;
      _updateState(AppState.initializing);
      _updateStatus('Iniciando aplicación...');

      // 1. Inicializar servicios básicos
      print('🔧 Inicializando servicios...');
      await _initializeServices();

      // 2. Solicitar permisos
      _updateState(AppState.requestingPermissions);
      _updateStatus('Solicitando permisos necesarios...');
      
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        throw Exception('Permisos requeridos no concedidos');
      }

      // 3. Obtener ubicación
      _updateState(AppState.gettingLocation);
      _updateStatus('Obteniendo tu ubicación...');
      
      final locationObtained = await _getCurrentLocation();
      if (!locationObtained) {
        throw Exception('No se pudo obtener la ubicación');
      }

      // 4. Buscar POIs
      _updateState(AppState.findingPOIs);
      _updateStatus('Buscando lugares interesantes cerca...');
      
      await _findNearbyPOIs();

      // 5. Generar mensaje de bienvenida
      _updateState(AppState.speaking);
      _updateStatus('Preparando mensaje de bienvenida...');
      
      await _generateAndSpeakWelcome();

      // 6. Aplicación lista para usar
      _updateState(AppState.ready);
      _updateStatus('¡Listo! Pulsa el botón del micrófono para comenzar');

    } catch (e) {
      print('❌ Error inicializando aplicación: $e');
      _lastError = e.toString();
      _updateState(AppState.error);
      _updateStatus('Error: ${e.toString()}');
      onError?.call(e.toString());
    }
  }

  /// Inicializa todos los servicios
  Future<void> _initializeServices() async {
    try {
      // Inicializar servicios en paralelo donde sea posible
      await Future.wait([
        _ttsService.initialize(),
        _speechService.initialize(),
      ]);

      // Inicializar servicios que necesitan configuración
      _poiService.initialize();
      _aiService.initialize();

      print('✅ Servicios inicializados correctamente');
    } catch (e) {
      print('❌ Error inicializando servicios: $e');
      rethrow;
    }
  }

  /// Solicita todos los permisos necesarios
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  Future<bool> _requestPermissions() async {
    try {
      print('🔐 Solicitando permisos...');
      
      final granted = await _permissionService.requestAllPermissions();
      
      if (granted) {
        print('✅ Todos los permisos concedidos');
        return true;
      } else {
        print('❌ Algunos permisos no fueron concedidos');
        return false;
      }
      
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual
  Future<bool> _getCurrentLocation() async {
    try {
      print('📍 Obteniendo ubicación...');
      
      _currentPosition = await _locationService.getCurrentLocation();
      
      if (_currentPosition != null) {
        print('✅ Ubicación obtenida: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        return true;
      } else {
        print('❌ No se pudo obtener la ubicación');
        return false;
      }
      
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      return false;
    }
  }

  /// Busca POIs cercanos
  Future<void> _findNearbyPOIs() async {
    try {
      if (_currentPosition == null) {
        print('❌ No hay posición disponible para buscar POIs');
        return;
      }

      print('🔍 Buscando POIs cercanos...');
      
      // Buscar el POI más interesante
      _currentPOI = await _poiService.findMostInterestingNearbyPOI(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 1000,
      );

      // Buscar POIs adicionales
      _nearbyPOIs = await _poiService.findNearbyPOIs(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 1000,
        limit: 10,
      );

      if (_currentPOI != null) {
        print('✅ POI principal encontrado: ${_currentPOI!.name}');
        
        // Crear contexto para la IA
        _currentContext = _poiService.createPOIContext(_currentPOI!, _currentPosition!);
      } else {
        print('⚠️ No se encontraron POIs interesantes cerca');
      }

      print('📍 Total POIs encontrados: ${_nearbyPOIs.length}');
      
    } catch (e) {
      print('❌ Error buscando POIs: $e');
    }
  }

  /// Genera y reproduce mensaje de bienvenida
  Future<void> _generateAndSpeakWelcome() async {
    try {
      print('🤖 Generando mensaje de bienvenida...');
      
      final welcomeMessage = await _aiService.generateWelcomeMessage(
        position: _currentPosition,
        nearbyPOI: _currentPOI,
      );

      print('🗣️ Reproduciendo bienvenida...');
      await _ttsService.speak(welcomeMessage);
      
    } catch (e) {
      print('❌ Error generando bienvenida: $e');
      // Bienvenida de fallback
      await _ttsService.speak(
        '¡Hola! Soy tu asistente turístico. ¿En qué puedo ayudarte?'
      );
    }
  }

  /// Inicia una conversación manual (activada por botón)
  Future<void> startConversation() async {
    if (_currentState != AppState.ready && _currentState != AppState.conversationActive) {
      print('⚠️ No se puede iniciar conversación en estado: $_currentState');
      return;
    }

    print('🔄 Iniciando conversación...');
    _isInConversation = true;
    _shouldContinueListening = true;
    
    await _listenForUserInput();
  }

  /// Finaliza la conversación
  Future<void> stopConversation() async {
    print('🛑 Finalizando conversación...');
    
    _isInConversation = false;
    _shouldContinueListening = false;
    
    // Detener servicios de audio
    await _speechService.cancel();
    await _ttsService.stop();
    
    _updateState(AppState.ready);
    _updateStatus('Conversación finalizada. Pulsa el micrófono para comenzar otra');
  }

  /// Continúa la conversación después de una respuesta
  Future<void> _continueConversation() async {
    if (_isInConversation && _shouldContinueListening && _isRunning) {
      print('🔄 Continuando conversación...');
      
      // Pequeña pausa antes de escuchar de nuevo
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_shouldContinueListening) {
        await _listenForUserInput();
      }
    }
  }

  /// Escucha entrada del usuario (con fallback a entrada de texto)
  Future<void> _listenForUserInput() async {
    try {
      _updateState(AppState.listening);
      _updateStatus('Escuchando... Habla ahora o usa entrada de texto');
      
      print('👂 Escuchando entrada del usuario...');
      
      // Verificar permisos
      final hasPermission = await _speechService.hasPermission;
      if (!hasPermission) {
        final granted = await _speechService.requestPermission();
        if (!granted) {
          print('⚠️ Sin permisos de micrófono, usando entrada de texto');
          _triggerTextInput();
          return;
        }
      }
      
      final userInput = await _speechService.startListening(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        localeId: 'es-ES',
      );

      if (userInput != null && userInput.trim().isNotEmpty) {
        print('📝 Usuario dijo: "$userInput"');
        
        // Verificar comandos de control
        if (_isStopCommand(userInput)) {
          await stopConversation();
          return;
        }
        
        await _processUserInput(userInput);
      } else {
        print('⚠️ No se detectó entrada de voz');
        
        if (_isInConversation) {
          _updateState(AppState.conversationActive);
          _updateStatus('No escuché nada. Habla de nuevo o di "terminar"');
          await _continueConversation();
        } else {
          _updateState(AppState.ready);
          _updateStatus('Listo. Pulsa el micrófono para otra pregunta');
        }
      }
      
    } catch (e) {
      print('❌ Error en entrada de voz: $e');
      _triggerTextInput();
    }
  }
  
  /// Callback para entrada de texto (se llamará desde la UI)
  Function(String)? onTextInputRequested;
  
  void _triggerTextInput() {
    _updateState(AppState.ready);
    _updateStatus('Entrada de texto disponible');
    onTextInputRequested?.call('Entrada de texto activada');
  }
  
  /// Procesa entrada de texto directamente
  Future<void> processTextInput(String userInput) async {
    if (userInput.trim().isEmpty) return;
    
    print('⌨️ Entrada de texto: "$userInput"');
    
    // Verificar comandos de control
    if (_isStopCommand(userInput)) {
      await stopConversation();
      return;
    }
    
    await _processUserInput(userInput);
  }

  /// Verifica si el usuario quiere terminar la conversación
  bool _isStopCommand(String input) {
    final lowerInput = input.toLowerCase().trim();
    final stopWords = [
      'terminar', 'finalizar', 'parar', 'stop', 'salir', 
      'adiós', 'hasta luego', 'fin', 'basta', 'ya está'
    ];
    
    return stopWords.any((word) => lowerInput.contains(word));
  }

  /// Procesa la entrada del usuario
  Future<void> _processUserInput(String userInput) async {
    try {
      _updateState(AppState.processing);
      _updateStatus('Procesando tu pregunta...');
      
      print('🤖 Generando respuesta para: "$userInput"');
      
      final response = await _aiService.generateTourismResponse(
        userQuestion: userInput,
        userPosition: _currentPosition,
        contextPOI: _currentPOI,
        nearbyPOIs: _nearbyPOIs,
      );

      if (response.isNotEmpty) {
        await _speakResponse(response);
      } else {
        await _speakResponse('Lo siento, no pude generar una respuesta. ¿Podrías repetir tu pregunta?');
      }
      
    } catch (e) {
      print('❌ Error procesando entrada: $e');
      await _speakResponse('Lo siento, ocurrió un error procesando tu pregunta. ¿Puedes intentar de nuevo?');
    }
  }

  /// Reproduce respuesta de la IA
  Future<void> _speakResponse(String response) async {
    try {
      _updateState(AppState.speaking);
      _updateStatus('Hablando...');
      
      print('🗣️ Reproduciendo respuesta: "$response"');
      await _ttsService.speak(response);
      
      // Decidir si continuar la conversación o volver a ready
      if (_isInConversation) {
        _updateState(AppState.conversationActive);
        _updateStatus('Listo para la siguiente pregunta. Di "terminar" para finalizar');
        await _continueConversation();
      } else {
        _updateState(AppState.ready);
        _updateStatus('Listo. Pulsa el micrófono para otra pregunta');
      }
      
    } catch (e) {
      print('❌ Error reproduciendo respuesta: $e');
      _updateState(AppState.ready);
    }
  }

  /// Actualiza ubicación manualmente
  Future<void> updateLocation() async {
    try {
      _updateStatus('Actualizando ubicación...');
      
      final success = await _getCurrentLocation();
      if (success) {
        await _findNearbyPOIs();
        _updateStatus('Ubicación actualizada');
      } else {
        _updateStatus('Error actualizando ubicación');
      }
      
    } catch (e) {
      print('❌ Error actualizando ubicación: $e');
      _updateStatus('Error: ${e.toString()}');
    }
  }

  /// Reinicia la aplicación
  Future<void> restartApp() async {
    try {
      print('🔄 Reiniciando aplicación...');
      
      await stopApp();
      await Future.delayed(const Duration(seconds: 1));
      await initializeApp();
      
    } catch (e) {
      print('❌ Error reiniciando aplicación: $e');
      _lastError = e.toString();
      _updateState(AppState.error);
    }
  }

  /// Detiene la aplicación
  Future<void> stopApp() async {
    try {
      print('🛑 Deteniendo aplicación...');
      
      _isRunning = false;
      _isInConversation = false;
      _shouldContinueListening = false;
      
      // Detener servicios de audio
      await _speechService.cancel();
      await _ttsService.stop();
      
      // Detener seguimiento de ubicación
      _locationService.stopLocationTracking();
      
      _updateState(AppState.initializing);
      _updateStatus('Aplicación detenida');
      
    } catch (e) {
      print('❌ Error deteniendo aplicación: $e');
    }
  }

  /// Actualiza el estado de la aplicación
  void _updateState(AppState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged?.call(newState);
      print('📊 Estado cambiado a: $newState');
    }
  }

  /// Actualiza el estado de status
  void _updateStatus(String status) {
    onStatusUpdate?.call(status);
    print('💬 Status: $status');
  }

  /// Limpia recursos
  void dispose() {
    print('🗑️ Disposing AppOrchestrator...');
    
    _isRunning = false;
    
    _speechService.dispose();
    _ttsService.dispose();
    _locationService.dispose();
    
    onStateChanged = null;
    onError = null;
    onStatusUpdate = null;
  }
}