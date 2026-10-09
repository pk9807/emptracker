import 'package:flutter_test/flutter_test.dart';
import 'package:services/services.dart';

void main() {
  group('Phase 6: Language Detection Tests', () {
    test('Detects Hindi Devanagari script', () {
      expect(AiLanguageDetector.detect('रवि अभी कहाँ है?'), equals('hi'));
      expect(AiLanguageDetector.detect('आज कितने शॉप्स पेंडिंग हैं?'), equals('hi'));
    });

    test('Detects Hinglish Roman Hindi script', () {
      expect(AiLanguageDetector.detect('Ravi abhi kaha hai?'), equals('hinglish'));
      expect(AiLanguageDetector.detect('Aaj mere kitne shops pending hain?'), equals('hinglish'));
      expect(AiLanguageDetector.detect('Mera route dikhao'), equals('hinglish'));
    });

    test('Detects Standard English', () {
      expect(AiLanguageDetector.detect('Show my pending shops'), equals('en'));
      expect(AiLanguageDetector.detect('Summarize attendance report for today'), equals('en'));
    });
  });

  group('Phase 6: Offline AI Knowledge & Stale Data Guardrails', () {
    final offlineService = OfflineAiService();

    test('Answers app navigation FAQ offline in Hindi/Hinglish', () {
      final res = offlineService.handleOfflineQuery('attendance kaise lagaye');
      expect(res.isLiveQueryBlocked, isFalse);
      expect(res.message, contains('Punch In'));
    });

    test('Answers visit FAQ offline in English', () {
      final res = offlineService.handleOfflineQuery('how to do a shop visit?');
      expect(res.isLiveQueryBlocked, isFalse);
      expect(res.message, contains('Check In'));
    });

    test('Blocks live employee location query when offline without fabricating coordinates', () {
      final res = offlineService.handleOfflineQuery('Ravi abhi kaha hai?');
      expect(res.isLiveQueryBlocked, isTrue);
      expect(res.message, contains('Live location'));
    });

    test('Blocks offline write actions safely', () {
      final res = offlineService.handleOfflineQuery('Ravi ko task assign kardo');
      expect(res.isLiveQueryBlocked, isTrue);
      expect(res.message, contains('server connection'));
    });

    test('Strict Domain Hardening: Rejects out-of-scope queries in Hindi/Hinglish', () {
      final resCricket = offlineService.handleOfflineQuery('Cricket IPL match score kya hai?');
      expect(resCricket.source, equals('domain_guardrail_hardened'));
      expect(resCricket.message, contains('EmpTracker'));

      final resMovie = offlineService.handleOfflineQuery('Koi achhi movie recommend karo');
      expect(resMovie.source, equals('domain_guardrail_hardened'));
      expect(resMovie.message, contains('EmpTracker'));
    });

    test('Strict Domain Hardening: Rejects out-of-scope queries in English', () {
      final res = offlineService.handleOfflineQuery('What is the recipe for biryani?');
      expect(res.source, equals('domain_guardrail_hardened'));
      expect(res.message, contains('strictly configured to assist only with EmpTracker'));
    });
  });

  group('Phase 6: Voice Speech & TTS Providers', () {
    test('Speech provider initializes and handles state transitions', () async {
      final speech = DefaultSpeechRecognitionProvider();
      expect(speech.state, equals(SpeechRecognitionState.idle));
      
      final initialized = await speech.initialize();
      expect(initialized, isTrue);

      final hasPermission = await speech.requestPermission();
      expect(hasPermission, isTrue);
    });

    test('TTS provider speaks and stops cleanly', () async {
      final tts = DefaultTextToSpeechProvider();
      expect(tts.state, equals(TtsState.stopped));

      await tts.speak('Namaste Ravi', locale: 'hi-IN');
      expect(tts.state, equals(TtsState.playing));

      await tts.stop();
      expect(tts.state, equals(TtsState.stopped));
    });
  });
}
