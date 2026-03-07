import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../main.dart';

/// Records audio segments for AI training data collection.
/// Each segment corresponds to a single chant line.
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  String? _currentChantId;
  int _currentLineIndex = 0;
  DateTime? _recordingStart;
  String? _deviceInfo;

  bool get isRecording => _currentPath != null;

  Future<void> init() async {
    _deviceInfo = await _getDeviceInfo();
  }

  /// Start recording a segment for a specific chant line.
  Future<bool> startSegment({
    required String chantId,
    required int lineIndex,
  }) async {
    if (!await _recorder.hasPermission()) {
      return false;
    }

    final dir = await _getRecordingDir();
    final fileName = '${chantId}_line${lineIndex}_${DateTime.now().millisecondsSinceEpoch}.wav';
    _currentPath = '${dir.path}/$fileName';
    _currentChantId = chantId;
    _currentLineIndex = lineIndex;
    _recordingStart = DateTime.now();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _currentPath!,
    );

    return true;
  }

  /// Stop recording and upload the segment.
  Future<bool> stopAndUpload() async {
    if (_currentPath == null) return false;

    final path = await _recorder.stop();
    if (path == null) {
      _reset();
      return false;
    }

    final durationMs = _recordingStart != null
        ? DateTime.now().difference(_recordingStart!).inMilliseconds
        : 0;

    // Read file and convert to base64
    try {
      final file = File(path);
      if (!await file.exists()) {
        _reset();
        return false;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // Upload
      final ok = await syncService.uploadAudioSample(
        chantId: _currentChantId!,
        lineIndex: _currentLineIndex,
        audioBase64: base64Audio,
        durationMs: durationMs,
        format: 'wav',
        deviceInfo: _deviceInfo,
      );

      // Clean up local file after upload
      if (ok) {
        await file.delete();
      }

      _reset();
      return ok;
    } catch (e) {
      debugPrint('Recording upload failed: $e');
      _reset();
      return false;
    }
  }

  /// Cancel current recording without uploading.
  Future<void> cancel() async {
    await _recorder.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _reset();
  }

  void dispose() {
    _recorder.dispose();
  }

  void _reset() {
    _currentPath = null;
    _currentChantId = null;
    _currentLineIndex = 0;
    _recordingStart = null;
  }

  Future<Directory> _getRecordingDir() async {
    final appDir = await getTemporaryDirectory();
    final recordDir = Directory('${appDir.path}/aipray_recordings');
    if (!await recordDir.exists()) {
      await recordDir.create(recursive: true);
    }
    return recordDir;
  }

  Future<String> _getDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return 'web_${info.browserName.name}';
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return 'android_${info.model}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return 'ios_${info.model}';
      }
    } catch (_) {}
    return 'unknown';
  }
}
