import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIConversationNotifier extends StateNotifier<AsyncValue<String?>> {
  AIConversationNotifier(this._aiService) : super(const AsyncValue.data(null));

  final AIService _aiService;
  String? _currentContext;

  void setContext(String context) {
    _currentContext = context;
  }

  Future<void> generateResponse(String userMessage) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _aiService.generateResponse(
        userMessage: userMessage,
        context: _currentContext ?? '',
      );
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> generateWelcomeMessage(String? poiContext) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _aiService.generateWelcomeMessage(poiContext);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> generateTourismResponse({
    required String question,
    required String locationContext,
    String? poiDetails,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _aiService.generateTourismResponse(
        question: question,
        locationContext: locationContext,
        poiDetails: poiDetails,
      );
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearResponse() {
    state = const AsyncValue.data(null);
  }
}

final aiConversationProvider = StateNotifierProvider<AIConversationNotifier, AsyncValue<String?>>((ref) {
  final aiService = ref.read(aiServiceProvider);
  return AIConversationNotifier(aiService);
});
