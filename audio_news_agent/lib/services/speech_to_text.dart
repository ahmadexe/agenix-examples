import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> initialize() async {
    await _speech.initialize();
  }

  Future<String> listenOnce() async {
    final completer = Completer<String>();
    String finalText = '';

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          finalText = result.recognizedWords;
          if (!completer.isCompleted) {
            _speech.stop();
            completer.complete(finalText);
          }
        }
      },
      // pauseFor: const Duration(seconds: 60),
      listenOptions: stt.SpeechListenOptions(partialResults: false),
      localeId: 'en_US',
    );

    return completer.future;
  }

  Future<void> pauseListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> stop() async => await _speech.stop();
  void cancel() => _speech.cancel();
  bool get isListening => _speech.isListening;
}
