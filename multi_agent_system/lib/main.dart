import 'package:agenix/agenix.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:multi_agent_system/firebase_options.dart';
import 'package:multi_agent_system/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenix Basic Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatbotScreen(),
    );
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _isLoading = false;
  String _response = 'Awaiting for response...';

  // Image Data
  XFile? media;
  Uint8List? imageData;

  bool isAgentReady = false;
  late final Agent agent;
  Future<void> initAgent() async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    agent = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Data Finding Agent',
      role: 'This agent is used to gather and find large amounts of data.',
      pathToSystemData: 'assets/agent1.json',
    );

    agent.toolRegistry.registerTool(
      FindDataTool(
        name: 'find_data',
        description: 'This tool should be used if the user asks to find data.',
        parameters: [],
      ),
    );

    final agent2 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Statistic Agent',
      role:
          'These agent analyzes data using statistics, whenever large amount of data is needed to be analyzed this agent should be used.',
      pathToSystemData: 'assets/agent2.json',
    );

    agent2.toolRegistry.registerTool(
      AnalyzeDataTool(
        name: 'analyze_data',
        description:
            'This tool should be used if the user asks to analyze data.',
        parameters: [
          ParameterSpecification(
            name: 'data',
            type: 'String',
            description: 'The data to be analyzed.',
            required: true,
          ),
        ],
      ),
    );

    final agent3 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Writer Agent',
      role: 'This agent is used to write articles and blog posts.',
      pathToSystemData: 'assets/agent3.json',
    );

    agent3.toolRegistry.registerTool(
      WriteBlogTool(
        name: 'write_article',
        description:
            'This tool should be used if the user asks to write an article or a blog using some data.',
        parameters: [
          ParameterSpecification(
            name: 'analyzedData',
            type: 'String',
            description:
                'This is the analyzed and processed data that should be used to write an article.',
            required: true,
          ),
        ],
      ),
    );

    setState(() {
      isAgentReady = true;
    });
  }

  @override
  void initState() {
    super.initState();

    initAgent();
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Agenix Basic Example')),
      body:
          !isAgentReady
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(controller: controller),
                    ElevatedButton(
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            media = image;
                          });
                        }

                        final Uint8List data = await image!.readAsBytes();
                        setState(() {
                          imageData = data;
                        });
                      },
                      child: Text('Add Image'),
                    ),
                    const SizedBox(height: 16),
                    !_isLoading
                        ? ElevatedButton(
                          onPressed: () async {
                            final userMessageRaw = controller.text;
                            final userMessage = AgentMessage(
                              content: userMessageRaw,
                              generatedAt: DateTime.now(),
                              isFromAgent: false,
                              imageData: imageData,
                            );
                            setState(() {
                              _isLoading = true;
                            });
                            // Call the agent to get a response
                            final res = await agent.generateResponse(
                              convoId: '1',
                              userMessage: userMessage,
                            );

                            setState(() {
                              _isLoading = false;
                              _response = res.content;
                            });
                          },
                          child: const Text('Send'),
                        )
                        : const CircularProgressIndicator(),

                    const SizedBox(height: 16),
                    Text(_response, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
    );
  }
}

class FindDataTool extends Tool {
  FindDataTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message:
          'Flutter is awesome! It is an open-source community-driven framework for building native, hybrid, and multi-platform apps from a single codebase.',
    );
  }
}

class AnalyzeDataTool extends Tool {
  AnalyzeDataTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message:
          '''Analyzed Data: Flutter is an open-source UI software development toolkit created by Google. It allows developers to build natively compiled applications for mobile, web, desktop, and embedded devices from a single codebase, using the Dart programming language.

          Flutter uses the Skia graphics engine to render UIs, providing high performance and full control over every pixel on the screen. The framework supports a reactive and declarative programming model, similar to React, making it easier to manage state and UI changes.

          As of 2025, Flutter has a strong and growing developer base with millions of users worldwide. It is widely used in both startups and enterprises. Major companies like Google, BMW, eBay, Alibaba, and Toyota use Flutter in production.

          Flutter's mobile support is stable and widely adopted, while web and desktop support are now considered production-ready. Web builds still face challenges like large bundle sizes and limited SEO capabilities, but performance has improved with upcoming WebAssembly support. Desktop applications built with Flutter are increasingly being used in cross-platform scenarios.

          The Dart language has matured with recent updates (Dart 3.x), adding advanced features like pattern matching, improved null safety, and better concurrency with isolates. While Dart is less mainstream than languages like JavaScript or Kotlin, it is fast, expressive, and tailored for UI development.

          Flutter’s package ecosystem on pub.dev has grown to over 33,000 packages, providing support for databases, device features, and third-party services. However, some niche packages are still underdeveloped or less maintained compared to native ecosystems.

          A growing trend in 2025 is the integration of Flutter with AI platforms. Tools for integrating    with Google Gemini, OpenAI, and other large language models are becoming common, enabling new types of applications such as AI chatbots, smart tools, and personalized assistants.''',
    );
  }
}

class WriteBlogTool extends Tool {
  WriteBlogTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message: 'Flutter is awesome and this is an article.',
    );
  }
}
