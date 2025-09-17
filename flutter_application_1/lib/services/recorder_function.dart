// ignore_for_file: library_private_types_in_public_api
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;
  String? _filePath;

  AudioRecorder();

  /// Initialize recorder
  Future<void> init() async {
    if (_isInitialized) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }
    try {
      _recorder = FlutterSoundRecorder();
      // openRecorder wraps audio session setup; guard with try/catch
      await _recorder!.openRecorder();
      _isInitialized = true;
    } catch (e) {
      print("❌ Recorder init error: $e");
      // Clean up if partially initialized
      try {
        await _recorder?.closeRecorder();
      } catch (_) {}
      _recorder = null;
      _isInitialized = false;
      rethrow;
    }
  }

  /// Start recording
  Future<void> startRecording({String? fileName}) async {
    if (!_isInitialized) await init();
    if (_recorder == null) return;
    if (_recorder!.isRecording) return;

    final dir = await getTemporaryDirectory();
    final name =
        fileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    _filePath = '${dir.path}/$name';

    try {
      await _recorder?.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);
    } catch (e) {
      print("❌ startRecording error: $e");
    }
  }

  /// Stop recording and return File
  Future<File?> stopRecording() async {
    if (_recorder == null || !_recorder!.isRecording) return null;

    try {
      await _recorder!.stopRecorder();
    } catch (e) {
      print("❌ stopRecording error: $e");
    }

    if (_filePath != null) {
      return File(_filePath!);
    }
    return null;
  }

  /// Return last recorded file
  File? getRecordedFile() {
    if (_filePath != null) {
      return File(_filePath!);
    }
    return null;
  }

  /// Check recording status
  bool get isRecording => _recorder?.isRecording ?? false;
  // เปิดให้ตรวจสอบสถานะจากภายนอก
  bool get isInitialized => _isInitialized;

  /// Dispose recorder
  Future<void> dispose() async {
    if (_recorder != null) {
      try {
        await _recorder!.closeRecorder();
      } catch (e) {
        print("❌ dispose recorder error: $e");
      }
      _recorder = null;
    }
    _isInitialized = false;
  }
}
