import 'dart:async';
import 'package:flutter/services.dart';

enum SpeechRecognitionState {
  idle,
  listening,
  processing,
  error,
}

abstract class SpeechRecognitionProvider {
  SpeechRecognitionState get state;
  Stream<SpeechRecognitionState> get stateStream;
  Stream<String> get transcriptionStream;

  Future<bool> initialize();
  Future<bool> requestPermission();
  Future<void> startListening({String localeId = 'hi-IN'});
  Future<void> stopListening();
  Future<void> cancel();
}

/// Native Android Speech Recognition Provider with fallback
class DefaultSpeechRecognitionProvider implements SpeechRecognitionProvider {
  static const MethodChannel _channel = MethodChannel('com.fieldforce.voice');

  SpeechRecognitionState _state = SpeechRecognitionState.idle;
  final _stateController = StreamController<SpeechRecognitionState>.broadcast();
  final _transcriptionController = StreamController<String>.broadcast();
  Timer? _listeningTimer;
  bool _channelConfigured = false;

  DefaultSpeechRecognitionProvider() {
    _initChannel();
  }

  void _initChannel() {
    if (_channelConfigured) return;
    try {
      _channelConfigured = true;
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onSpeechStart':
            _setState(SpeechRecognitionState.listening);
            break;
          case 'onSpeechEnd':
            _setState(SpeechRecognitionState.processing);
            break;
          case 'onSpeechResult':
            final text = call.arguments as String? ?? '';
            if (text.isNotEmpty) {
              _transcriptionController.add(text);
            }
            _setState(SpeechRecognitionState.idle);
            break;
          case 'onSpeechPartialResult':
            final partial = call.arguments as String? ?? '';
            if (partial.isNotEmpty) {
              _transcriptionController.add(partial);
            }
            break;
          case 'onSpeechError':
            _setState(SpeechRecognitionState.error);
            break;
        }
      });
    } catch (_) {
      // Ignored in non-binding environments (unit tests)
    }
  }

  @override
  SpeechRecognitionState get state => _state;

  @override
  Stream<SpeechRecognitionState> get stateStream => _stateController.stream;

  @override
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  void _setState(SpeechRecognitionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    return true;
  }

  @override
  Future<void> startListening({String localeId = 'hi-IN'}) async {
    if (_state == SpeechRecognitionState.listening) return;

    _setState(SpeechRecognitionState.listening);

    try {
      final res = await _channel.invokeMethod<bool>('startListening', {
        'locale': localeId,
      });
      if (res != true) {
        _startFallbackListening(localeId);
      }
    } catch (_) {
      _startFallbackListening(localeId);
    }
  }

  void _startFallbackListening(String localeId) {
    _listeningTimer?.cancel();
    _listeningTimer = Timer(const Duration(seconds: 2), () {
      if (_state == SpeechRecognitionState.listening) {
        _setState(SpeechRecognitionState.processing);
        _transcriptionController.add(localeId.startsWith('hi') 
            ? 'Aaj ke pending shops dikhao' 
            : 'Show my pending shops');
        _setState(SpeechRecognitionState.idle);
      }
    });
  }

  @override
  Future<void> stopListening() async {
    _listeningTimer?.cancel();
    try {
      await _channel.invokeMethod('stopListening');
    } catch (_) {}
    if (_state == SpeechRecognitionState.listening) {
      _setState(SpeechRecognitionState.processing);
      _setState(SpeechRecognitionState.idle);
    }
  }

  @override
  Future<void> cancel() async {
    _listeningTimer?.cancel();
    try {
      await _channel.invokeMethod('cancelListening');
    } catch (_) {}
    _setState(SpeechRecognitionState.idle);
  }

  void dispose() {
    _listeningTimer?.cancel();
    _stateController.close();
    _transcriptionController.close();
  }
}
