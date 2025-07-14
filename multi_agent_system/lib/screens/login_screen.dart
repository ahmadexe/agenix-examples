import 'package:flutter/material.dart';
import 'package:multi_agent_system/screens/chat_screen.dart';
import 'package:multi_agent_system/services/calendar_service.dart';
import 'package:multi_agent_system/services/email_service.dart';
import 'package:multi_agent_system/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseService.signInWithGoogle();
            await EmailService().sendEmail();
            await CalendarService().bookEvent();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => ChatbotScreen()));
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
