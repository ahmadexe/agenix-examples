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
  static final TextEditingController _controller = TextEditingController(); // ✅ static to persist
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // optional: focus after build
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
    // ❌ Do not dispose _controller — it's static and shared
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmitted(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.fieldDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
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
