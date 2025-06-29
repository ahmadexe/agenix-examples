import 'dart:convert';

import 'package:agenix/agenix.dart';
import 'package:audio_news_agent/services/speech_to_text.dart';
import 'package:audio_news_agent/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    initializeSpeechToText();
    super.initState();
  }

  @override
  void dispose() {
    SpeechToTextService().cancel();
    super.dispose();
  }

  Future<void> initializeSpeechToText() async {
    await SpeechToTextService().initialize();
    setState(() {
      isReady = true;
    });
  }

  bool isReady = false;
  final TtsService _ttsService = TtsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio News Agent')),
      body: Column(
        children: [
          if (isReady)
            ElevatedButton(
              onPressed: () async {
                final text = await SpeechToTextService().listen();
                await _ttsService.speak(text);
              },
              child: Text('Speak'),
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
