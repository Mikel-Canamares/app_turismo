import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_orchestrator.dart';
import '../../core/providers/app_provider.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  String _statusMessage = 'Iniciando aplicación...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Configurar callbacks del orchestrator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupOrchestrator();
    });
  }

  void _setupOrchestrator() {
    final orchestrator = ref.read(appOrchestratorProvider);
    
    // Configurar callbacks
    orchestrator.onStateChanged = (AppState state) {
      if (mounted) {
        setState(() {
          _updateAnimations(state);
        });
      }
    };
    
    orchestrator.onStatusUpdate = (String status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    };
    
    orchestrator.onError = (String error) {
      if (mounted) {
        setState(() {
          _errorMessage = error;
        });
      }
    };
    
    // Inicializar la app
    orchestrator.initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(appState),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: _buildMainContent(appState),
                ),
              ),
              _buildControls(appState),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Turismo AI',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tu asistente turístico inteligente',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainContent(AppState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVisualIndicator(state),
        const SizedBox(height: 32),
        if (_isLoadingState(state)) 
          const CircularProgressIndicator(color: Colors.white),
        if (_isLoadingState(state)) 
          const SizedBox(height: 24),
        _buildStatusText(),
        const SizedBox(height: 16),
        _buildStateDescription(state),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildVisualIndicator(AppState state) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = state == AppState.listening ? _pulseAnimation.value : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getIndicatorColor(state),
              boxShadow: [
                BoxShadow(
                  color: _getIndicatorColor(state).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _getIndicatorIcon(state),
              size: 48,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Text(
      _statusMessage,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStateDescription(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStateDescription(state),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppState state) {
    final orchestrator = ref.read(appOrchestratorProvider);
    
    return Column(
      children: [
        // Botón principal del micrófono
        if (state == AppState.ready || state == AppState.conversationActive)
          _buildMicrophoneButton(state, orchestrator),
        
        const SizedBox(height: 16),
        
        // Controles secundarios
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.refresh,
              label: 'Reiniciar',
              onPressed: state != AppState.initializing 
                  ? () => orchestrator.restartApp()
                  : null,
            ),
            _buildControlButton(
              icon: Icons.my_location,
              label: 'Ubicación',
              onPressed: state == AppState.ready || state == AppState.error
                  ? () => orchestrator.updateLocation()
                  : null,
            ),
            if (orchestrator.isInConversation)
              _buildControlButton(
                icon: Icons.stop_circle,
                label: 'Terminar',
                onPressed: () => orchestrator.stopConversation(),
              )
            else
              _buildControlButton(
                icon: Icons.pause,
                label: 'Pausar',
                onPressed: state != AppState.initializing && state != AppState.error
                    ? () => orchestrator.stopApp()
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMicrophoneButton(AppState state, dynamic orchestrator) {
    final isInConversation = orchestrator.isInConversation;
    final isListening = state == AppState.listening;
    
    return GestureDetector(
      onTap: isListening ? null : () {
        if (isInConversation) {
          // Si está en conversación, terminarla
          orchestrator.stopConversation();
        } else {
          // Si no está en conversación, iniciarla
          orchestrator.startConversation();
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening 
              ? Colors.red[400] 
              : isInConversation 
                  ? Colors.orange[400]
                  : Colors.green[400],
          boxShadow: [
            BoxShadow(
              color: (isListening 
                  ? Colors.red[400] 
                  : isInConversation 
                      ? Colors.orange[400]
                      : Colors.green[400])!.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          isListening 
              ? Icons.mic 
              : isInConversation 
                  ? Icons.stop 
                  : Icons.mic_none,
          size: 32,
          color: Colors.white,
        ),
      ),
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
          iconSize: 32,
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _updateAnimations(AppState state) {
    switch (state) {
      case AppState.listening:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case AppState.speaking:
        _pulseController.reset();
        _waveController.repeat();
        break;
      case AppState.processing:
        _pulseController.reset();
        _waveController.repeat();
        break;
      default:
        _pulseController.reset();
        _waveController.reset();
        break;
    }
  }

  bool _isLoadingState(AppState state) {
    return state == AppState.initializing ||
           state == AppState.requestingPermissions ||
           state == AppState.gettingLocation ||
           state == AppState.findingPOIs ||
           state == AppState.processing;
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

  Color _getIndicatorColor(AppState state) {
    switch (state) {
      case AppState.listening:
        return Colors.blue[400]!;
      case AppState.speaking:
        return Colors.teal[400]!;
      case AppState.processing:
        return Colors.amber[400]!;
      case AppState.conversationActive:
        return Colors.indigo[400]!;
      case AppState.error:
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
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
        return Icons.mic;
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

  String _getStateDescription(AppState state) {
    switch (state) {
      case AppState.initializing:
        return 'Configurando tu asistente de turismo personalizado';
      case AppState.requestingPermissions:
        return 'Necesito acceso a tu ubicación y micrófono para funcionar';
      case AppState.gettingLocation:
        return 'Encontrando tu ubicación actual para buscar lugares cercanos';
      case AppState.findingPOIs:
        return 'Buscando los lugares más interesantes cerca de ti';
      case AppState.ready:
        return 'Pulsa el botón del micrófono para hacer preguntas';
      case AppState.listening:
        return 'Te estoy escuchando, habla con claridad';
      case AppState.processing:
        return 'Generando una respuesta personalizada para ti';
      case AppState.speaking:
        return 'Escucha mi respuesta, luego puedes continuar la conversación';
      case AppState.conversationActive:
        return 'Conversación activa. Sigue hablando o di "terminar"';
      case AppState.error:
        return 'Algo salió mal. Usa los controles para reintentar';
    }
  }
}