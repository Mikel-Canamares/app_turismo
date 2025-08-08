import 'package:flutter/material.dart';

/// Diálogo de entrada de texto como alternativa funcional
/// Permite interacción real mientras se desarrolla la funcionalidad de voz
class TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final Function(String) onSubmit;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.keyboard, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.chat_bubble_outline),
            ),
            maxLines: 3,
            minLines: 1,
            autofocus: true,
            enabled: !_isSubmitting,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrada temporal: Se mejorará con reconocimiento de voz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}

/// Función auxiliar para mostrar el diálogo
Future<void> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required Function(String) onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (context) => TextInputDialog(
      title: title,
      hint: hint,
      onSubmit: onSubmit,
    ),
  );
}
