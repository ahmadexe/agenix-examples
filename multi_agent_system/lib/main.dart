import 'dart:convert';

import 'package:agenix/agenix.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:multi_agent_system/firebase_options.dart';
import 'package:multi_agent_system/services/firebase_service.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
      title: 'Agenix Multi Agents Example',
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
      name: 'Orchestrator Agent',
      role:
          'This is the agent that communicates with the end user, and orchestrates the other agents. It does not perform any specific tasks itself. Hence it does not have tools either.',
      pathToSystemData: 'assets/agent1.json',
    );

    final agent2 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'News Agent',
      role:
          'Whenever the user needs to know about news of any kind, this agent should be used.',
      pathToSystemData: 'assets/agent2.json',
    );

    agent2.toolRegistry.registerTool(
      FindNewsTool(
        name: 'fetch_news_tool',
        description:
            'This tool should be used if the user asks for news. It will be used to find any type of news, like top headlines, sports news, or news in general. It searches the news from the internet.',
        parameters: [],
      ),
    );

    final agent3 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Manage Favourites Agent',
      role:
          'This agent is responsible for managing the favourites of the user. It can save and fetch the favourites of the user.',
      pathToSystemData: 'assets/agent3.json',
    );

    agent3.toolRegistry.registerTool(
      SaveFavouritesTool(
        name: 'save_favourite_news_tool',
        description:
            "This tool should be used to save the news that the user wants to mark as favourite. It will save the news in the database.",
        parameters: [
          ParameterSpecification(
            name: 'news',
            type: 'string',
            description:
                'This is the news that the user needs to save as favourite.',
            required: true,
          ),
        ],
      ),
    );

    agent3.toolRegistry.registerTool(
      FetchFavouriteNewsTool(
        name: 'fetch_favourite_news_tool',
        description:
            "This tool should be used to fetch the favourite news of the user. It will fetch the news from the database.",
        parameters: [],
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
      appBar: AppBar(title: const Text('Agenix Multi Agents Example')),
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

class FindNewsTool extends Tool {
  FindNewsTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    final key = dotenv.env['NEWS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('API key not found');
    }

    final client = http.Client();
    final uri = Uri.parse(
      "https://newsapi.org/v2/top-headlines?country=us&apiKey=$key",
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'Failed to fetch news: ${response.reasonPhrase}',
      );
    }

    final Map<String, dynamic> data =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message:
          'Here are the top headlines: ${data['articles'].map((e) => e['title']).join(', ')}',
      data: data,
      needsFurtherReasoning: true,
    );
  }
}

class SaveFavouritesTool extends Tool {
  SaveFavouritesTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    final news = params['news'] as String?;
    if (news == null || news.isEmpty) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'I can not filter the news right now, maybe some other time?',
      );
    }

    await FirebaseFirestore.instance.collection('favourites').add({
      'news': news,
    });

    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message: 'The news have been marked as favourite successfully!',
    );
  }
}

class FetchFavouriteNewsTool extends Tool {
  FetchFavouriteNewsTool({
    required super.name,
    required super.description,
    required super.parameters,
  });

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    final docs =
        await FirebaseFirestore.instance.collection('favourites').get();
    final news = docs.docs.map((e) => e.data()['news'] as String).toList();
    return ToolResponse(
      toolName: name,
      isRequestSuccessful: true,
      message: 'Here are the favourite news: ${news.join(', ')}',
    );
  }
}
