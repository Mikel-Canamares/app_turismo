import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_orchestrator.dart';
import '../../core/providers/app_provider.dart';

class ConversationPanel extends ConsumerStatefulWidget {
  const ConversationPanel({super.key});

  @override
  ConsumerState<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<ConversationPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orchestrator = ref.watch(appOrchestratorProvider);
    final appState = ref.watch(appStateProvider);
    
    // Configurar callback una sola vez
    orchestrator.onConversationUpdated ??= () {
      if (mounted) {
        setState(() {
          _scrollToBottom();
        });
      }
    };
    
    final history = orchestrator.conversationHistory;
    final lastUserInput = orchestrator.lastUserInput;
    final lastAIResponse = orchestrator.lastAIResponse;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 300 : 120,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStateColor(appState).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header con toggle
          _buildHeader(),
          
          // Contenido
          Expanded(
            child: _isExpanded 
                ? _buildFullConversation(history)
                : _buildLastExchange(lastUserInput, lastAIResponse),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              'Conversación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastExchange(String userInput, String aiResponse) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (userInput.isNotEmpty)
            _buildMessageBubble('Tú', userInput, Colors.blue, true),
          
          if (userInput.isNotEmpty && aiResponse.isNotEmpty)
            const SizedBox(height: 4),
            
          if (aiResponse.isNotEmpty)
            _buildMessageBubble('IA', aiResponse, Colors.green, false),
        ],
      ),
    );
  }

  Widget _buildFullConversation(List<Map<String, String>> history) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final entry = history[index];
          final sender = entry['sender'] ?? '';
          final message = entry['message'] ?? '';
          final isUser = sender == 'user';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: _buildMessageBubble(
              isUser ? 'Tú' : 'IA',
              message,
              isUser ? Colors.blue : Colors.green,
              isUser,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(String sender, String message, Color color, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(AppState state) {
    switch (state) {
      case AppState.ready:
        return Colors.green;
      case AppState.listening:
        return Colors.orange;
      case AppState.processing:
        return Colors.blue;
      case AppState.speaking:
        return Colors.purple;
      case AppState.conversationActive:
        return Colors.cyan;
      case AppState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

