import 'package:agenix/agenix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:multi_agent_system/configs/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final AgentMessage message;
  MessageBubble({super.key, required this.message});

  final ValueNotifier<bool> _copied = ValueNotifier(false);

  void _handleCopy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _copied.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      _copied.value = false;
    });
  }

  final ValueNotifier<bool> _isLiked = ValueNotifier(false);
  void _handleLike() {
    _isLiked.value = !_isLiked.value;
    _isDisliked.value = false;
  }

  final ValueNotifier<bool> _isDisliked = ValueNotifier(false);
  void _handleDislike() {
    _isDisliked.value = !_isDisliked.value;
    _isLiked.value = false;
  }

  @override
  Widget build(BuildContext context) {
    if (message.isFromAgent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.content, style: const TextStyle(color: Colors.white)),
          SizedBox(height: 10),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _copied,
                builder: (context, copied, _) {
                  return GestureDetector(
                    onTap: () => _handleCopy(message.content),
                    child: Icon(
                      copied ? Icons.check : Iconsax.copy,
                      size: 18,
                      color: copied ? AppTheme.primary : Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(width: 4),
              ValueListenableBuilder<bool>(
                valueListenable: _isLiked,
                builder: (context, isLiked, _) {
                  return GestureDetector(
                    onTap: () => _handleLike(),
                    child: Icon(
                      Iconsax.like_1,
                      size: 18,
                      color: isLiked ? AppTheme.primary : Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(width: 4),
              ValueListenableBuilder<bool>(
                valueListenable: _isDisliked,
                builder: (context, isDisliked, _) {
                  return GestureDetector(
                    onTap: () => _handleDislike(),
                    child: Icon(
                      Iconsax.dislike,
                      size: 18,
                      color: isDisliked ? Colors.red : Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
