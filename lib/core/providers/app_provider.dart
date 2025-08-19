import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_orchestrator.dart';

final appOrchestratorProvider = Provider<AppOrchestrator>((ref) {
  return AppOrchestrator();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._orchestrator) : super(AppState.initializing) {
    _orchestrator.onStateChanged = (newState) {
      state = newState;
    };
  }

  final AppOrchestrator _orchestrator;

  Future<void> initializeApp() async {
    await _orchestrator.initializeApp();
  }

  Future<void> restartApp() async {
    await _orchestrator.restartApp();
  }

  Future<void> stopApp() async {
    await _orchestrator.stopApp();
  }

  Future<void> updateLocation() async {
    await _orchestrator.updateLocation();
  }

  Future<void> startConversation() async {
    await _orchestrator.startConversation();
  }

  Future<void> stopConversation() async {
    await _orchestrator.stopConversation();
  }

  // ====== NUEVOS MÉTODOS PARA MANTENER PRESIONADO ======
  Future<bool> startListeningPressed() async {
    return await _orchestrator.startListeningPressed();
  }

  Future<String?> stopListeningPressed() async {
    return await _orchestrator.stopListeningPressed();
  }

  bool get isInConversation => _orchestrator.isInConversation;

  @override
  void dispose() {
    _orchestrator.dispose();
    super.dispose();
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final orchestrator = ref.read(appOrchestratorProvider);
  return AppStateNotifier(orchestrator);
});
