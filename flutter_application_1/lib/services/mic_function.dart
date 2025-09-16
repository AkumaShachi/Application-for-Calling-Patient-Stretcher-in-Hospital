import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MicController {
  late stt.SpeechToText _speech;
  bool isListening = false;
  String recognizedText = "";

  MicController() {
    _speech = stt.SpeechToText();
  }

  /// Initialize speech-to-text
  Future<void> init() async {
    if (!isListening) {
      try {
        bool available = await _speech.initialize();
        if (!available) {
          print("⚠️ Speech recognition not available");
        }
      } catch (e) {
        print("❌ Speech init error: $e");
      }
    }
  }

  /// Start listening
  Future<void> listen({
    required String? editingField,
    required Map<String, TextEditingController> controllers,
    String localeId = 'th_TH',
    VoidCallback? onUpdate,
  }) async {
    if (!isListening) {
      try {
        bool available = await _speech.initialize();
        if (!available) return;

        isListening = true;

        _speech.listen(
          localeId: localeId,
          onResult: (val) {
            recognizedText = val.recognizedWords;

            // อัปเดต controller ที่กำลังแก้ไข
            if (editingField != null && controllers.containsKey(editingField)) {
              controllers[editingField]!.text = recognizedText;
            }

            if (onUpdate != null) onUpdate();
          },
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        );
      } catch (e) {
        print("❌ Speech listen error: $e");
      }
    } else {
      await stop();
    }
  }

  /// Stop listening
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (e) {
      print("❌ Speech stop error: $e");
    }
    isListening = false;
  }
}
