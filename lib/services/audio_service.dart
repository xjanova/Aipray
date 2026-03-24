import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

typedef TranscriptCallback = void Function(String transcript, bool isFinal);
typedef StatusCallback = void Function(AudioServiceStatus status);

enum AudioServiceStatus {
  idle,
  initializing,
  listening,
  paused,
  error,
  notAvailable,
}

class AudioService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  AudioServiceStatus _status = AudioServiceStatus.idle;
  String _lastError = '';

  // Exponential backoff for restart retries
  int _consecutiveErrors = 0;
  static const int _maxRetries = 10;
  static const int _baseDelayMs = 300;
  static const int _maxDelayMs = 30000; // 30 seconds max

  TranscriptCallback? onTranscript;
  StatusCallback? onStatusChange;

  AudioServiceStatus get status => _status;
  bool get isListening => _isListening;
  String get lastError => _lastError;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _setStatus(AudioServiceStatus.initializing);

    try {
      _isInitialized = await _speech.initialize(
        onError: _onError,
        onStatus: _onSpeechStatus,
        debugLogging: kDebugMode,
      );

      if (!_isInitialized) {
        _setStatus(AudioServiceStatus.notAvailable);
        _lastError = 'Speech recognition not available on this device';
        return false;
      }

      _setStatus(AudioServiceStatus.idle);
      return true;
    } catch (e) {
      _setStatus(AudioServiceStatus.notAvailable);
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_isListening && _speech.isListening) return;

    try {
      _isListening = true;
      _setStatus(AudioServiceStatus.listening);

      await _speech.listen(
        onResult: _onResult,
        localeId: 'th-TH',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      _setStatus(AudioServiceStatus.error);
      _lastError = e.toString();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _consecutiveErrors = 0;
    await _speech.stop();
    _setStatus(AudioServiceStatus.idle);
  }

  void dispose() {
    _speech.stop();
    _speech.cancel();
    _isListening = false;
    _consecutiveErrors = 0;
    onTranscript = null;
    onStatusChange = null;
  }

  void _onResult(SpeechRecognitionResult result) {
    // Reset error count on successful result
    _consecutiveErrors = 0;
    onTranscript?.call(result.recognizedWords, result.finalResult);
  }

  void _onError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;

    // Auto-restart on transient errors with exponential backoff
    if (_isListening &&
        (error.errorMsg == 'error_no_match' ||
         error.errorMsg == 'error_speech_timeout')) {
      _restartWithBackoff();
      return;
    }

    _setStatus(AudioServiceStatus.error);
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && _isListening) {
      _restartWithBackoff();
    }
  }

  void _restartWithBackoff() {
    _consecutiveErrors++;

    if (_consecutiveErrors > _maxRetries) {
      _isListening = false;
      _lastError = 'เสียงสวดยังไม่ชัดเจน กรุณากดเริ่มฟังอีกครั้ง';
      _setStatus(AudioServiceStatus.error);
      _consecutiveErrors = 0;
      return;
    }

    // Exponential backoff: 300ms, 600ms, 1200ms, 2400ms, ...
    final delay = min(
      _baseDelayMs * pow(2, _consecutiveErrors - 1).toInt(),
      _maxDelayMs,
    );

    Future.delayed(Duration(milliseconds: delay), () {
      if (_isListening) startListening();
    });
  }

  void _setStatus(AudioServiceStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    onStatusChange?.call(newStatus);
  }
}
