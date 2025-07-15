import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:multi_agent_system/configs/app_theme.dart';

class ChatInputField extends StatefulWidget {
  final void Function(String) onSubmitted;

  const ChatInputField({super.key, required this.onSubmitted});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  static final TextEditingController _controller = TextEditingController();

  bool _isSending = false;

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    widget.onSubmitted(text);

    _controller.clear();

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.fieldDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              onSubmitted: (_) => _handleSend(),
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.send_2, color: Colors.white),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
