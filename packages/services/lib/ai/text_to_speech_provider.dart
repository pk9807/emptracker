import 'dart:async';
import 'package:flutter/services.dart';

enum TtsState {
  stopped,
  playing,
  paused,
}

abstract class TextToSpeechProvider {
  TtsState get state;
  Stream<TtsState> get stateStream;

  Future<void> speak(String text, {String locale = 'hi-IN'});
  Future<void> stop();
  Future<void> pause();
}

/// Native Android TextToSpeech Provider with automatic fallback
class DefaultTextToSpeechProvider implements TextToSpeechProvider {
  static const MethodChannel _channel = MethodChannel('com.fieldforce.voice');

  TtsState _state = TtsState.stopped;
  final _stateController = StreamController<TtsState>.broadcast();
  Timer? _speechTimer;
  bool _channelConfigured = false;

  DefaultTextToSpeechProvider() {
    _initChannel();
  }

  void _initChannel() {
    if (_channelConfigured) return;
    try {
      _channelConfigured = true;
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onTtsStart':
            _setState(TtsState.playing);
            break;
          case 'onTtsDone':
          case 'onTtsError':
            _setState(TtsState.stopped);
            break;
        }
      });
    } catch (_) {
      // Ignored in non-binding environments (unit tests)
    }
  }

  @override
  TtsState get state => _state;

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  void _setState(TtsState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  @override
  Future<void> speak(String text, {String locale = 'hi-IN'}) async {
    _speechTimer?.cancel();
    _setState(TtsState.playing);

    try {
      final res = await _channel.invokeMethod<bool>('speak', {
        'text': text,
        'locale': locale,
      });
      if (res != true) {
        _startFallbackTimer(text);
      }
    } catch (_) {
      // Fallback for tests / non-Android platforms
      _startFallbackTimer(text);
    }
  }

  void _startFallbackTimer(String text) {
    final wordCount = text.split(' ').length;
    final durationSeconds = (wordCount / 3).clamp(1, 10).toInt();

    _speechTimer = Timer(Duration(seconds: durationSeconds), () {
      if (_state == TtsState.playing) {
        _setState(TtsState.stopped);
      }
    });
  }

  @override
  Future<void> stop() async {
    _speechTimer?.cancel();
    try {
      await _channel.invokeMethod('stopTts');
    } catch (_) {}
    _setState(TtsState.stopped);
  }

  @override
  Future<void> pause() async {
    _speechTimer?.cancel();
    try {
      await _channel.invokeMethod('stopTts');
    } catch (_) {}
    _setState(TtsState.paused);
  }

  void dispose() {
    _speechTimer?.cancel();
    _stateController.close();
  }
}
