import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agenix/agenix.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:multi_agent_system/screens/login_screen.dart';
import 'package:multi_agent_system/services/calendar_service.dart';
import 'package:multi_agent_system/services/email_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _isLoading = false;
  String _response = 'Awaiting for response...';

  bool isAgentReady = false;
  late final Agent agent;
  Future<void> initAgent() async {
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key not found');
    }
    agent = await Agent.create(
      dataStore: CustomDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Orchestrator Agent',
      role:
          'This is the agent that communicates with the end user, and orchestrates the other agents. It does not perform any specific tasks itself. Hence it does not have tools either.',
      pathToSystemData: 'assets/orchestrator.json',
    );

    final agent2 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'News Agent',
      role:
          'Whenever the user needs to know about news of any kind, this agent should be used.',
      pathToSystemData: 'assets/news_agent.json',
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
      pathToSystemData: 'assets/favourites_agent.json',
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

    final agent4 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Email Agent',
      role:
          'You are Ahmad\'s email agent, your purpose is to send emails to the user and fetch emails from the user.',
      pathToSystemData: 'assets/email_agent.json',
    );

    agent4.toolRegistry.registerTool(
      SendEmailTool(
        name: 'send_email_tool',
        llm: agent4.llm,
        description:
            "This tool should be used whenever the you are asked to send emails to anyone. Do not ask user for their gmail password, just use this tool. It will send emails to the user.",
        parameters: [
          ParameterSpecification(
            name: 'email',
            type: 'string',
            description:
                'This is the email address that the user needs to send an email to.',
            required: true,
          ),
          ParameterSpecification(
            name: 'content',
            type: 'string',
            description:
                'This is the content that the user needs to send in the email.',
            required: true,
          ),
        ],
      ),
    );

    final agent5 = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Calendar Agent',
      role:
          'You are Ahmad\'s calendar agent, your purpose is to book events on the calender.',
      pathToSystemData: 'assets/calendar_agent.json',
    );

    agent5.toolRegistry.registerTool(
      BookEventTool(
        name: 'book_event_tool',
        llm: agent5.llm,
        description:
            "This tool should be used to book events on the calender. It will book events on the calender.",
        parameters: [
          ParameterSpecification(
            name: 'event',
            type: 'string',
            description:
                'This is the event that the user needs to book on the calender.',
            required: true,
          ),
          ParameterSpecification(
            name: 'date',
            type: 'string',
            description:
                'This is the date that the user needs to book the event on.',
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
      appBar: AppBar(
        title: const Text('Agenix Multi Agents Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          !isAgentReady
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(controller: controller),
                    const SizedBox(height: 16),
                    !_isLoading
                        ? ElevatedButton(
                          onPressed: () async {
                            final userMessageRaw = controller.text;
                            final userMessage = AgentMessage(
                              content: userMessageRaw,
                              generatedAt: DateTime.now(),
                              isFromAgent: false,
                            );
                            setState(() {
                              _isLoading = true;
                            });
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

class BookEventTool extends Tool {
  BookEventTool({
    required super.name,
    required super.description,
    required super.parameters,
    required this.llm,
  });

  final LLM llm;

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    final String? event = params['event'] as String?;
    final String? date = params['date'] as String?;
    if (event == null || event.isEmpty || date == null || date.isEmpty) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'Please provide an event and a date to book.',
      );
    }
    try {
      final parsedDate = await llm.generate(
        prompt:
            'Parse this date to a standard ISO date, always strictly return a date nothing else, if it is ambiguous, return the closest date to the provided date: ${date.trim()}',
      );
      final cleanDate = parsedDate
          .trim()
          .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
          .replaceAll('"', '');
      final DateTime dateTime = DateTime.parse(cleanDate);
      final calService = CalendarService();
      await calService.bookEvent(event, dateTime);
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: true,
        message: 'I have booked the event for you! Anything else master?',
      );
    } catch (e) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'Failed to book event: $e',
      );
    }
  }
}

class SendEmailTool extends Tool {
  SendEmailTool({
    required super.name,
    required super.description,
    required super.parameters,
    required this.llm,
  });

  final LLM llm;

  @override
  Future<ToolResponse> run(Map<String, dynamic> params) async {
    final email = params['email'] as String?;
    final content = params['content'] as String?;
    if (email == null || email.isEmpty || content == null || content.isEmpty) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'Please provide an email address and content to send.',
      );
    }
    try {
      final subject = await llm.generate(
        prompt: 'Generate a subject for this email, DO NOT ADD ANYTHING IN THE RESPONSE, just the subject: ${content.trim()}',
      );
      final emailService = EmailService();
      await emailService.sendEmail(content, email, subject);
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: true,
        message: 'I have sent the email for you! Anything else master?',
      );
    } catch (e) {
      return ToolResponse(
        toolName: name,
        isRequestSuccessful: false,
        message: 'Failed to send email: $e',
      );
    }
  }
}

class CustomDataStore extends DataStore {
  @override
  Future<void> deleteConversation(String conversationId, {Object? metaData}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Conversation>> getConversations(
    String convoId, {
    Object? metaData,
  }) {
    return Future.value([]);
  }

  @override
  Future<List<AgentMessage>> getMessages(
    String conversationId, {
    Object? metaData,
  }) {
    return Future.value([]);
  }

  @override
  Future<void> saveMessage(
    String convoId,
    AgentMessage msg, {
    Object? metaData,
  }) {
    throw UnimplementedError();
  }
}
