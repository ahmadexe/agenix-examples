import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:multi_agent_system/configs/app_theme.dart';
import 'package:multi_agent_system/providers/agent_provider.dart';
import 'package:multi_agent_system/providers/custom_data_store.dart';
import 'package:multi_agent_system/screens/login_screen.dart';
import 'package:multi_agent_system/widgets/chat_input_field.dart';
import 'package:multi_agent_system/widgets/message_bubble.dart';
import 'package:multi_agent_system/widgets/typing_indicator.dart';
import 'package:provider/provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Provider.of<AgentProvider>(context, listen: false).initAgent(context);
      setState(() {
        _isInit = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = Provider.of<AgentProvider>(context);
    final customDataStore = Provider.of<CustomDataStore>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Agenix Multi Agents Example',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body:
          !agentProvider.isAgentInitialized
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            customDataStore.messages["convo1"]?.length ?? 0,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final message =
                              customDataStore.messages["convo1"]![index];
                          return MessageBubble(message: message);
                        },
                      ),
                    ),
                    if (agentProvider.isWriting)
                      const TypingIndicator(showIndicator: true),
                    ChatInputField(onSubmitted: agentProvider.getReply),
                  ],
                ),
              ),
    );
  }
}
