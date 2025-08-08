import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

final ttsInitializationProvider = FutureProvider<void>((ref) async {
  final ttsService = ref.read(ttsServiceProvider);
  await ttsService.initialize();
});

class TTSNotifier extends StateNotifier<bool> {
  TTSNotifier(this._ttsService) : super(false);

  final TTSService _ttsService;

  bool get isSpeaking => _ttsService.isSpeaking;

  Future<void> speak(String text) async {
    state = true;
    await _ttsService.speak(text);
    // El estado se actualizará automáticamente cuando termine via callback
  }

  Future<void> speakAndWait(String text) async {
    state = true;
    await _ttsService.speakAndWait(text);
    state = false;
  }

  Future<void> stop() async {
    await _ttsService.stop();
    state = false;
  }
}

final ttsNotifierProvider = StateNotifierProvider<TTSNotifier, bool>((ref) {
  final ttsService = ref.read(ttsServiceProvider);
  return TTSNotifier(ttsService);
});
