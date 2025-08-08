import 'package:flutter/material.dart';

// Enum simple para estados
enum SimpleAppState {
  starting,
  permissions,
  location,
  findingPlaces,
  ready,
  error,
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  SimpleAppState _currentState = SimpleAppState.starting;
  String _statusMessage = 'Iniciando Turismo AI...';

  @override
  void initState() {
    super.initState();
    // Iniciar proceso sin usar providers complejos
    _startSimpleInitialization();
  }

  Future<void> _startSimpleInitialization() async {
    // Simular inicialización paso a paso
    await _updateState(SimpleAppState.permissions, 'Solicitando permisos...');
    await Future.delayed(const Duration(seconds: 2));
    
    await _updateState(SimpleAppState.location, 'Obteniendo ubicación...');
    await Future.delayed(const Duration(seconds: 2));
    
    await _updateState(SimpleAppState.findingPlaces, 'Buscando lugares cercanos...');
    await Future.delayed(const Duration(seconds: 2));
    
    await _updateState(SimpleAppState.ready, '¡Listo! Habla para comenzar');
  }

  Future<void> _updateState(SimpleAppState newState, String message) async {
    if (mounted) {
      setState(() {
        _currentState = newState;
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(_currentState),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: _buildMainContent(_currentState),
                ),
              ),
              _buildControls(_currentState),
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

  Widget _buildMainContent(SimpleAppState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVisualIndicator(state),
        const SizedBox(height: 32),
        if (state != SimpleAppState.ready) 
          const CircularProgressIndicator(color: Colors.white),
        if (state != SimpleAppState.ready) 
          const SizedBox(height: 24),
        _buildStatusText(state),
        const SizedBox(height: 16),
        _buildStateDescription(state),
      ],
    );
  }

  Widget _buildVisualIndicator(SimpleAppState state) {
    return Container(
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
    );
  }

  Widget _buildStatusText(SimpleAppState state) {
    return Text(
      _statusMessage,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStateDescription(SimpleAppState state) {
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

  Widget _buildControls(SimpleAppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.refresh,
          label: 'Reiniciar',
          onPressed: state != SimpleAppState.starting 
              ? () => _startSimpleInitialization()
              : null,
        ),
        _buildControlButton(
          icon: Icons.my_location,
          label: 'Ubicación',
          onPressed: state == SimpleAppState.ready
              ? () => _updateState(SimpleAppState.location, 'Actualizando ubicación...')
              : null,
        ),
        _buildControlButton(
          icon: Icons.settings,
          label: 'Debug',
          onPressed: () => print('Estado actual: $state'),
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

  Color _getBackgroundColor(SimpleAppState state) {
    switch (state) {
      case SimpleAppState.starting:
        return Colors.grey[800]!;
      case SimpleAppState.permissions:
        return Colors.orange[700]!;
      case SimpleAppState.location:
        return Colors.blue[700]!;
      case SimpleAppState.findingPlaces:
        return Colors.purple[700]!;
      case SimpleAppState.ready:
        return Colors.green[700]!;
      case SimpleAppState.error:
        return Colors.red[700]!;
    }
  }

  Color _getIndicatorColor(SimpleAppState state) {
    switch (state) {
      case SimpleAppState.starting:
        return Colors.grey[400]!;
      case SimpleAppState.permissions:
        return Colors.orange[400]!;
      case SimpleAppState.location:
        return Colors.blue[400]!;
      case SimpleAppState.findingPlaces:
        return Colors.purple[400]!;
      case SimpleAppState.ready:
        return Colors.green[400]!;
      case SimpleAppState.error:
        return Colors.red[400]!;
    }
  }

  IconData _getIndicatorIcon(SimpleAppState state) {
    switch (state) {
      case SimpleAppState.starting:
        return Icons.hourglass_empty;
      case SimpleAppState.permissions:
        return Icons.security;
      case SimpleAppState.location:
        return Icons.location_on;
      case SimpleAppState.findingPlaces:
        return Icons.search;
      case SimpleAppState.ready:
        return Icons.mic;
      case SimpleAppState.error:
        return Icons.error;
    }
  }

  String _getStateDescription(SimpleAppState state) {
    switch (state) {
      case SimpleAppState.starting:
        return 'Configurando tu asistente de turismo personalizado';
      case SimpleAppState.permissions:
        return 'Solicitando acceso a ubicación y micrófono';
      case SimpleAppState.location:
        return 'Encontrando tu ubicación actual para buscar lugares cercanos';
      case SimpleAppState.findingPlaces:
        return 'Buscando los lugares más interesantes cerca de ti';
      case SimpleAppState.ready:
        return 'Todo listo! Habla para hacer preguntas sobre lugares turísticos';
      case SimpleAppState.error:
        return 'Algo salió mal. Usa los controles para reintentar';
    }
  }
}
