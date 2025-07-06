import 'dart:convert';

import 'package:agenix/agenix.dart';
import 'package:audio_news_agent/services/speech_to_text.dart';
import 'package:audio_news_agent/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FetchNewsAgentScreen extends StatefulWidget {
  const FetchNewsAgentScreen({super.key});

  @override
  State<FetchNewsAgentScreen> createState() => _FetchNewsAgentScreenState();
}

class _FetchNewsAgentScreenState extends State<FetchNewsAgentScreen> {
  final SpeechToTextService _speechService = SpeechToTextService();
  @override
  void initState() {
    super.initState();
    initializeSpeechToText();
    initAgent();
  }

  @override
  void dispose() {
    _continueListening = false;
    _speechService.cancel();
    super.dispose();
  }

  bool _continueListening = false;
  bool _isListening = false;

  Future<void> _startConversationLoop() async {
    _continueListening = true;

    while (_continueListening) {
      setState(() => _isListening = true);

      final result = await _speechService.listenOnce();

      setState(() {
        _isListening = false;
      });

      if (result.trim().isEmpty) {
        continue;
      }

      final userMessage = AgentMessage(
        content: result,
        generatedAt: DateTime.now(),
        isFromAgent: false,
      );

      final res = await agent.generateResponse(
        convoId: 'flutter_ai',
        userMessage: userMessage,
      );

      await _speechService.stop();
      await _ttsService.speak(res.content);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> initializeSpeechToText() async {
    await _speechService.initialize();
    setState(() {
      isSpeechEngineReady = true;
    });
  }

  Future<void> initAgent() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    agent = await Agent.create(
      dataStore: DataStore.firestoreDataStore(),
      llm: LLM.geminiLLM(apiKey: apiKey, modelName: 'gemini-1.5-flash'),
      name: 'Agent News',
      role:
          'This agent is responsible for finding the latest news, whenever the user asks for news of any sort, this agent find it.',
      pathToSystemData: 'assets/agent1.json',
    );

    agent.toolRegistry.registerTool(
      FindNewsTool(
        name: 'find_news_tool',
        description:
            "This tool finds news of all sorts, whenever a user asks to find news this tool should be used.",
        parameters: [],
      ),
    );

    setState(() {
      isAgentReady = true;
    });
  }

  bool isSpeechEngineReady = false;
  final TtsService _ttsService = TtsService();
  late final Agent agent;
  bool isAgentReady = false;
  bool isThinking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio News Agent')),
      body: Column(
        children: [
          if (isAgentReady && isSpeechEngineReady)
            ElevatedButton.icon(
              onPressed: _startConversationLoop,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(
                _isListening ? 'Stop Listening' : 'Start Conversation',
              ),
            ),
        ],
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
