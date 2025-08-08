import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/speech_service.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

final speechInitializationProvider = FutureProvider<bool>((ref) async {
  final speechService = ref.read(speechServiceProvider);
  return await speechService.initialize();
});

class SpeechNotifier extends StateNotifier<AsyncValue<String?>> {
  SpeechNotifier(this._speechService) : super(const AsyncValue.data(null));

  final SpeechService _speechService;

  Future<void> listenForCommand({String? prompt}) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _speechService.listenForCommand(prompt: prompt);
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    state = const AsyncValue.data(null);
  }

  void clearResult() {
    state = const AsyncValue.data(null);
  }
}

final speechNotifierProvider = StateNotifierProvider<SpeechNotifier, AsyncValue<String?>>((ref) {
  final speechService = ref.read(speechServiceProvider);
  return SpeechNotifier(speechService);
});
