import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:multi_agent_system/firebase_options.dart';
import 'package:multi_agent_system/providers/agent_provider.dart';
import 'package:multi_agent_system/providers/custom_data_store.dart';
import 'package:multi_agent_system/screens/chatbot_screen.dart';
import 'package:multi_agent_system/screens/login_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CustomDataStore>(
          create: (context) => CustomDataStore(),
        ),
        ChangeNotifierProvider<AgentProvider>(
          create: (context) => AgentProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Agenix Multi Agents Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              return const ChatbotScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
