import 'package:agenix/agenix.dart';
import 'package:audio_news_agent/services/speech_to_text.dart';
import 'package:audio_news_agent/services/tts_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoreFavNewsAgentScreen extends StatefulWidget {
  const StoreFavNewsAgentScreen({super.key});

  @override
  State<StoreFavNewsAgentScreen> createState() =>
      _StoreFavNewsAgentScreenState();
}

class _StoreFavNewsAgentScreenState extends State<StoreFavNewsAgentScreen> {
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
  bool _isFirstPass = true;

  Future<void> _startConversationLoop() async {
    _continueListening = true;

    while (_continueListening) {
      if (_isFirstPass) {
        await _ttsService.speak("Find me the latest news.");
        await Future.delayed(const Duration(seconds: 12));

        setState(() {
          _isFirstPass = false;
        });
      }
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
      await Future.delayed(const Duration(seconds: 4));
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
      name: 'Save News Agent',
      role:
          'This agent is responsible for saving the users favourite news. This agent will save the news in the database, using the provided tools.',
      pathToSystemData: 'assets/agent2.json',
    );

    agent.toolRegistry.registerTool(
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

    agent.toolRegistry.registerTool(
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

  bool isSpeechEngineReady = false;
  final TtsService _ttsService = TtsService();
  late final Agent agent;
  bool isAgentReady = false;
  bool isThinking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourite News Agent')),
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
