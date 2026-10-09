class AiLanguageDetector {
  static const Set<String> _hinglishKeywords = {
    'kaha', 'kahan', 'hai', 'hain', 'aaj', 'kal', 'parso', 'kitne', 'kitna', 'kitni',
    'mera', 'meri', 'mere', 'ka', 'ke', 'ki', 'ko', 'se', 'me', 'mein', 'par',
    'batao', 'dikhao', 'karo', 'karein', 'chahiye', 'hoga', 'hogi', 'paas',
    'abhi', 'sabse', 'pehle', 'baad', 'dukan', 'dhoondo', 'de do', 'kardo',
    'haziri', 'chhutti', 'kaunsa', 'kaun'
  };

  /// Returns 'hi' (Devanagari), 'hinglish' (Roman Hindi), or 'en' (English)
  static String detect(String input) {
    final text = input.trim();
    if (text.isEmpty) return 'en';

    // Devanagari range: \u0900 to \u097F
    final devanagariRegex = RegExp(r'[\u0900-\u097F]');
    if (devanagariRegex.hasMatch(text)) {
      return 'hi';
    }

    final words = text.toLowerCase().split(RegExp(r'[\s,\.\?!;:]+'));
    int matches = 0;
    for (final word in words) {
      if (_hinglishKeywords.contains(word)) {
        matches++;
      }
    }

    if (matches > 0 && (words.length <= 3 || (matches / words.length) >= 0.15)) {
      return 'hinglish';
    }

    return 'en';
  }

  /// Get appropriate TTS locale
  static String getTtsLocale(String langCode) {
    switch (langCode) {
      case 'hi':
      case 'hinglish':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }
}
