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

    // Inicializar la app automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).initializeApp();
    });
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
    
    // Controlar animaciones según el estado
    _updateAnimations(appState);

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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu asistente de turismo por voz',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
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
        _buildStatusText(state),
        const SizedBox(height: 24),
        _buildStateDescription(state),
      ],
    );
  }

  Widget _buildVisualIndicator(AppState state) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state == AppState.listening ? _pulseAnimation.value : 1.0,
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

  Widget _buildStatusText(AppState state) {
    return Text(
      _getStatusText(state),
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

  Widget _buildControls(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.refresh,
          label: 'Reiniciar',
          onPressed: state != AppState.initializing 
              ? () => ref.read(appStateProvider.notifier).restartApp()
              : null,
        ),
        _buildControlButton(
          icon: Icons.my_location,
          label: 'Ubicación',
          onPressed: state == AppState.ready
              ? () => ref.read(appStateProvider.notifier).updateLocation()
              : null,
        ),
        _buildControlButton(
          icon: Icons.stop,
          label: 'Detener',
          onPressed: state != AppState.initializing && state != AppState.error
              ? () => ref.read(appStateProvider.notifier).stopApp()
              : null,
        ),
      ],
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
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(onPressed != null ? 0.2 : 0.1),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
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
      case AppState.error:
        return Icons.error;
    }
  }

  String _getStatusText(AppState state) {
    switch (state) {
      case AppState.initializing:
        return 'Iniciando...';
      case AppState.requestingPermissions:
        return 'Solicitando Permisos';
      case AppState.gettingLocation:
        return 'Obteniendo Ubicación';
      case AppState.findingPOIs:
        return 'Buscando Lugares';
      case AppState.ready:
        return 'Listo para Escuchar';
      case AppState.listening:
        return 'Escuchando...';
      case AppState.processing:
        return 'Procesando...';
      case AppState.speaking:
        return 'Hablando...';
      case AppState.error:
        return 'Error';
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
        return 'Hazme cualquier pregunta sobre lugares turísticos';
      case AppState.listening:
        return 'Te estoy escuchando, habla con claridad';
      case AppState.processing:
        return 'Generando una respuesta personalizada para ti';
      case AppState.speaking:
        return 'Escucha mi respuesta, luego puedes hacer otra pregunta';
      case AppState.error:
        return 'Algo salió mal. Usa los controles para reintentar';
    }
  }
}
