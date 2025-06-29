import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A service for handling speech-to-text functionality.
/// This service uses the `speech_to_text` package to convert spoken words into text.
/// It provides methods to initialize the service, start listening for speech,
/// stop listening, and cancel the current speech recognition session.
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// To initialize the speech-to-text service.
  /// This method must be called before using the service to ensure that
  /// the speech recognition engine is ready.
  Future<void> initialize() async {
    await _speech.initialize();
  }


  /// Starts listening for speech and returns the recognized text. Whenever a pause is detected, it will return the text.
  Future<String> listen({Duration timeout = const Duration(seconds: 5)}) async {
    final completer = Completer<String>();
    String transcript = '';

    _speech.listen(
      onResult: (result) {
        transcript = result.recognizedWords;
        if (result.finalResult) {
          completer.complete(transcript);
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 2), 
      localeId: 'en_US',
    );

    // Safety timeout in case nothing is returned
    Future.delayed(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        completer.complete(transcript); // Might be empty
      }
    });

    return completer.future;
  }

  void stop() {
    _speech.stop();
  }

  void cancel() {
    _speech.cancel();
  }

  bool get isListening => _speech.isListening;
}
