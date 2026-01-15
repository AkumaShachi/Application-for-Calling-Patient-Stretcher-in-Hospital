// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MicController {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String recognizedText = "";
  bool _isInitialized = false;

  // ข้อความต้นทางเมื่อเริ่มการฟัง (ใช้เพื่อ append)

  bool get isListening => _isListening; // ...existing code...
  // ตรวจสอบสถานะ initialization จากภายนอก
  bool get isInitialized => _isInitialized;

  MicController() {
    _speech = stt.SpeechToText();
  }

  /// Initialize speech-to-text
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      bool available = await _speech.initialize();
      _isInitialized = available;
      if (!available) {
        print("⚠️ Speech recognition not available");
      }
    } catch (e) {
      print("❌ Speech init error: $e");
      _isInitialized = false;
    }
  }

  /// Start listening
  Future<void> listen({
    required String? editingField,
    // controllers parameterยังคงส่งเข้ามาแต่จะไม่ถูกแก้ไขแบบ live ที่นี่
    required Map<String, TextEditingController> controllers,
    String localeId = 'th_TH',
    VoidCallback? onUpdate,
  }) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }
    if (!_isListening) {
      try {
        // เคลียร์ผลก่อนเริ่มฟังใหม่
        recognizedText = "";
        _isListening = true;

        _speech.listen(
          localeId: localeId,
          onResult: (val) {
            // เก็บผลล่าสุดไว้เท่านั้น (ไม่เขียนลง controller ที่นี่)
            recognizedText = val.recognizedWords;
            if (onUpdate != null) onUpdate();
          },
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        );
      } catch (e) {
        print("❌ Speech listen error: $e");
        _isListening = false;
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
    } finally {
      _isListening = false;
    }
  }
}
