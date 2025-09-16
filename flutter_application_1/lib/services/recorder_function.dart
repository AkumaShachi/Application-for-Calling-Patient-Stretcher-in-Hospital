// ignore_for_file: library_private_types_in_public_api
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
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

    await _recorder.openRecorder();
    _isInitialized = true;
  }

  /// Start recording
  Future<void> startRecording({String? fileName}) async {
    if (!_isInitialized) await init();
    if (_recorder.isRecording) return;

    final dir = await getTemporaryDirectory();
    final name =
        fileName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    _filePath = '${dir.path}/$name';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV, // WAV หรือเปลี่ยนเป็น mp3 ก็ได้
    );
  }

  /// Stop recording and return File
  Future<File?> stopRecording() async {
    if (!_recorder.isRecording) return null;

    await _recorder.stopRecorder();

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
  bool get isRecording => _recorder.isRecording;

  /// Dispose recorder
  Future<void> dispose() async {
    await _recorder.closeRecorder();
  }
}
