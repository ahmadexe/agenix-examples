import 'package:audio_news_agent/services/speech_to_text.dart';
import 'package:audio_news_agent/services/tts_service.dart';
import 'package:flutter/material.dart';

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
