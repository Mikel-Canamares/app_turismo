import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../core/services/app_orchestrator.dart';
import 'text_input_dialog.dart';
import '../../core/providers/app_provider.dart';
import '../../features/poi/models/poi_model.dart';
import 'conversation_panel.dart';

class MapWithVoiceScreen extends ConsumerStatefulWidget {
  const MapWithVoiceScreen({super.key});

  @override
  ConsumerState<MapWithVoiceScreen> createState() => _MapWithVoiceScreenState();
}

class _MapWithVoiceScreenState extends ConsumerState<MapWithVoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _statusMessage = 'Iniciando aplicación...';
  String? _errorMessage;
  LatLng? _currentLocation;
  List<PointOfInterest> _nearbyPOIs = [];

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Inicializar app usando el provider correcto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() {
    // Usar el provider de estado en lugar de callbacks directos
    final appStateNotifier = ref.read(appStateProvider.notifier);
    appStateNotifier.initializeApp();
  }
  
  void _updateFromOrchestrator() {
    final orchestrator = ref.read(appOrchestratorProvider);
    
    // Actualizar ubicación y POIs
    if (orchestrator.currentPosition != null) {
      _currentLocation = LatLng(
        orchestrator.currentPosition!.latitude,
        orchestrator.currentPosition!.longitude,
      );
    }
    _nearbyPOIs = orchestrator.nearbyPOIs;
  }

  void _startConversationWithOptions(AppStateNotifier appStateNotifier, AppOrchestrator orchestrator) {
    // Configurar callback para entrada de texto
    orchestrator.onTextInputRequested = (_) {
      _showTextInput(orchestrator);
    };
    
    // Iniciar conversación
    appStateNotifier.startConversation();
  }
  
  void _showTextInput(AppOrchestrator orchestrator) {
    showTextInputDialog(
      context,
      title: 'Escribe tu pregunta',
      hint: 'Ej: ¿Qué puedo visitar aquí? ¿Cuéntame sobre este lugar?',
      onSubmit: (text) async {
        await orchestrator.processTextInput(text);
      },
    );
  }

  // ====== NUEVOS MÉTODOS PARA MANTENER PRESIONADO ======
  void _startListeningPressed(AppOrchestrator orchestrator) async {
    try {
      print('🎤 Iniciando escucha con botón presionado...');
      await orchestrator.startListeningPressed();
    } catch (e) {
      print('❌ Error iniciando escucha presionada: $e');
    }
  }
  
  void _stopListeningPressed(AppOrchestrator orchestrator) async {
    try {
      print('🎤 Deteniendo escucha al soltar botón...');
      
      final result = await orchestrator.stopListeningPressed();
      
      if (result != null && result.trim().isNotEmpty) {
        print('📝 Texto reconocido: "$result"');
        // Procesar directamente con el orchestrator
        await orchestrator.processTextInput(result);
      } else {
        print('⚠️ No se reconoció texto - Mostrando opciones');
        _showSpeechOptions(orchestrator);
      }
      
    } catch (e) {
      print('❌ Error deteniendo escucha presionada: $e');
    }
  }

  void _showSpeechOptions(AppOrchestrator orchestrator) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué quieres saber?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se detectó voz. Elige una opción:'),
            const SizedBox(height: 16),
            _buildQuickQuestionButton(orchestrator, "¿Qué puedo visitar aquí?"),
            _buildQuickQuestionButton(orchestrator, "Cuéntame sobre este lugar"),
            _buildQuickQuestionButton(orchestrator, "¿Qué hay de interesante?"),
            _buildQuickQuestionButton(orchestrator, "¿Dónde puedo comer?"),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTextInput(orchestrator);
              },
              child: const Text('Escribir pregunta personalizada'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionButton(AppOrchestrator orchestrator, String question) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          orchestrator.processTextInput(question);
        },
        child: Text(question, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    // Actualizar animaciones basado en el estado
    _updateAnimations(appState);
    
    // Actualizar datos del orchestrator
    _updateFromOrchestrator();
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal
            Column(
              children: [
                // Header con estado actual
                _buildHeader(appState),
                
                // Mapa principal
                Expanded(
                  flex: 3,
                  child: _buildMap(),
                ),
                
                // Panel de estado y controles
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    color: _getBackgroundColor(appState).withValues(alpha: 0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildStatusPanel(appState),
                          const SizedBox(height: 16),
                          _buildVoiceControls(appState),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Panel de conversación superpuesto
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: const ConversationPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: _getBackgroundColor(state),
      child: Column(
        children: [
          Text(
            'Turismo AI',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Obteniendo ubicación...'),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.turismo_ai',
        ),
        MarkerLayer(
          markers: [
            // Marcador de ubicación actual
            Marker(
              point: _currentLocation!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person_pin,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Marcadores de POIs
            ..._nearbyPOIs.map((poi) => Marker(
              point: LatLng(poi.latitude, poi.longitude),
              width: 35,
              height: 35,
              child: GestureDetector(
                onTap: () => _showPOIInfo(poi),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getPOIColor(poi.typeInSpanish),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getPOIIcon(poi.typeInSpanish),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPanel(AppState state) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              _getIndicatorIcon(state),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStateName(state),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getStateDescription(state),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceControls(AppState state) {
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final orchestrator = ref.read(appOrchestratorProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botón principal del micrófono
        _buildMicrophoneButton(state, appStateNotifier, orchestrator),
        
        // Botón de ubicación
        _buildControlButton(
          icon: Icons.my_location,
          label: 'Ubicación',
          onPressed: state == AppState.ready || state == AppState.error
              ? () => appStateNotifier.updateLocation()
              : null,
        ),
        
        // Botón de reiniciar
        _buildControlButton(
          icon: Icons.refresh,
          label: 'Reiniciar',
          onPressed: state != AppState.initializing 
              ? () => appStateNotifier.restartApp()
              : null,
        ),
        
        // Botón terminar conversación o pausar
        if (appStateNotifier.isInConversation)
          _buildControlButton(
            icon: Icons.stop_circle,
            label: 'Terminar',
            onPressed: () => appStateNotifier.stopConversation(),
          )
        else
          _buildControlButton(
            icon: Icons.pause,
            label: 'Pausar',
            onPressed: state != AppState.initializing && state != AppState.error
                ? () => appStateNotifier.stopApp()
                : null,
          ),
          
        // Botón limpiar conversación
        _buildControlButton(
          icon: Icons.clear_all,
          label: 'Limpiar',
          onPressed: state != AppState.initializing
              ? () => orchestrator.clearConversationHistory()
              : null,
        ),
      ],
    );
  }

  Widget _buildMicrophoneButton(AppState state, AppStateNotifier appStateNotifier, AppOrchestrator orchestrator) {
    final isInConversation = appStateNotifier.isInConversation;
    final isListening = state == AppState.listening;
    final canInteract = state == AppState.ready || state == AppState.conversationActive;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isListening ? _pulseAnimation.value : 1.0;
        
        return AvatarGlow(
          animate: isListening,
          glowColor: isListening ? Colors.red : Colors.green,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              // MANTENER PRESIONADO PARA HABLAR
              onTapDown: !canInteract ? null : (_) {
                print('🎤 Iniciando escucha (mantener presionado)...');
                _startListeningPressed(orchestrator);
              },
              onTapUp: !canInteract ? null : (_) {
                print('🎤 Finalizando escucha (soltar botón)...');
                _stopListeningPressed(orchestrator);
              },
              onTapCancel: () {
                print('🎤 Cancelando escucha...');
                _stopListeningPressed(orchestrator);
              },
              
              // LONG PRESS PARA ENTRADA DE TEXTO
              onLongPress: !canInteract ? null : () {
                print('🎤 Long press - Entrada de texto');
                _showTextInput(orchestrator);
              },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !canInteract
                    ? Colors.grey[400]
                    : isListening 
                        ? Colors.red[400] 
                        : isInConversation 
                            ? Colors.orange[400]
                            : Colors.green[400],
                boxShadow: canInteract ? [
                  BoxShadow(
                    color: (isListening 
                        ? Colors.red[400] 
                        : isInConversation 
                            ? Colors.orange[400]
                            : Colors.green[400])!.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ] : null,
              ),
              child: Icon(
                isListening 
                    ? Icons.mic 
                    : isInConversation 
                        ? Icons.stop 
                        : Icons.mic_none,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 24,
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.all(8),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showPOIInfo(PointOfInterest poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(poi.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${poi.typeInSpanish}'),
            const SizedBox(height: 8),
            Text('Distancia: ${poi.distance < 1000 ? "${poi.distance.toStringAsFixed(0)}m" : "${(poi.distance/1000).toStringAsFixed(1)}km"}'),
            if (poi.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Descripción: ${poi.description}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Iniciar conversación sobre este POI específico
              final orchestrator = ref.read(appOrchestratorProvider);
              orchestrator.startConversation();
            },
            child: const Text('Preguntar sobre este lugar'),
          ),
        ],
      ),
    );
  }

  void _updateAnimations(AppState state) {
    switch (state) {
      case AppState.listening:
        _pulseController.repeat(reverse: true);
        break;
      default:
        _pulseController.reset();
        break;
    }
  }

  Color _getBackgroundColor(AppState state) {
    switch (state) {
      case AppState.initializing:
        return Colors.grey[800]!;
      case AppState.requestingPermissions:
        return Colors.orange[700]!;
      case AppState.gettingLocation:
        return Colors.blue[700]!;
      case AppState.findingPOIs:
        return Colors.purple[700]!;
      case AppState.ready:
        return Colors.green[700]!;
      case AppState.listening:
        return Colors.blue[600]!;
      case AppState.processing:
        return Colors.amber[700]!;
      case AppState.speaking:
        return Colors.teal[600]!;
      case AppState.conversationActive:
        return Colors.indigo[700]!;
      case AppState.error:
        return Colors.red[700]!;
    }
  }

  // ====== MÉTODOS PARA POIs EN EL MAPA ======
  
  Color _getPOIColor(String type) {
    switch (type.toLowerCase()) {
      case 'museo':
      case 'museum':
        return Colors.purple[600]!;
      case 'iglesia':
      case 'catedral':
      case 'church':
        return Colors.brown[600]!;
      case 'parque':
      case 'park':
        return Colors.green[600]!;
      case 'restaurante':
      case 'restaurant':
        return Colors.orange[600]!;
      case 'hotel':
        return Colors.blue[600]!;
      case 'monumento':
      case 'monument':
        return Colors.grey[600]!;
      case 'teatro':
      case 'theatre':
        return Colors.red[600]!;
      case 'mercado':
      case 'market':
        return Colors.yellow[700]!;
      case 'playa':
      case 'beach':
        return Colors.cyan[600]!;
      default:
        return Colors.red[600]!;
    }
  }
  
  IconData _getPOIIcon(String type) {
    switch (type.toLowerCase()) {
      case 'museo':
      case 'museum':
        return Icons.museum;
      case 'iglesia':
      case 'catedral':
      case 'church':
        return Icons.church;
      case 'parque':
      case 'park':
        return Icons.park;
      case 'restaurante':
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'monumento':
      case 'monument':
        return Icons.account_balance;
      case 'teatro':
      case 'theatre':
        return Icons.theater_comedy;
      case 'mercado':
      case 'market':
        return Icons.store;
      case 'playa':
      case 'beach':
        return Icons.beach_access;
      default:
        return Icons.place;
    }
  }

  IconData _getIndicatorIcon(AppState state) {
    switch (state) {
      case AppState.initializing:
        return Icons.hourglass_empty;
      case AppState.requestingPermissions:
        return Icons.security;
      case AppState.gettingLocation:
        return Icons.location_on;
      case AppState.findingPOIs:
        return Icons.search;
      case AppState.ready:
        return Icons.mic_none;
      case AppState.listening:
        return Icons.mic;
      case AppState.processing:
        return Icons.psychology;
      case AppState.speaking:
        return Icons.volume_up;
      case AppState.conversationActive:
        return Icons.chat;
      case AppState.error:
        return Icons.error;
    }
  }

  String _getStateName(AppState state) {
    switch (state) {
      case AppState.initializing:
        return 'Iniciando...';
      case AppState.requestingPermissions:
        return 'Permisos';
      case AppState.gettingLocation:
        return 'Ubicación';
      case AppState.findingPOIs:
        return 'Buscando lugares';
      case AppState.ready:
        return 'Listo';
      case AppState.listening:
        return 'Escuchando';
      case AppState.processing:
        return 'Procesando';
      case AppState.speaking:
        return 'Hablando';
      case AppState.conversationActive:
        return 'En conversación';
      case AppState.error:
        return 'Error';
    }
  }

  String _getStateDescription(AppState state) {
    switch (state) {
      case AppState.initializing:
        return 'Configurando servicios...';
      case AppState.requestingPermissions:
        return 'Solicitando permisos...';
      case AppState.gettingLocation:
        return 'Obteniendo ubicación GPS...';
      case AppState.findingPOIs:
        return 'Buscando lugares de interés...';
      case AppState.ready:
        return 'Pulsa el micrófono para preguntar';
      case AppState.listening:
        return 'Habla ahora';
      case AppState.processing:
        return 'Generando respuesta...';
      case AppState.speaking:
        return 'Escucha la respuesta';
      case AppState.conversationActive:
        return 'Sigue hablando o di "terminar"';
      case AppState.error:
        return 'Error - usa los controles';
    }
  }
}

