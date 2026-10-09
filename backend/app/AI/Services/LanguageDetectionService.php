<?php

namespace App\AI\Services;

class LanguageDetectionService
{
    /**
     * Common Romanized Hindi / Hinglish tokens
     */
     protected array $hinglishTokens = [
        'kaha', 'kahan', 'hai', 'hain', 'aaj', 'kal', 'parso', 'kitne', 'kitna', 'kitni',
        'mera', 'meri', 'mere', 'ka', 'ke', 'ki', 'ko', 'se', 'me', 'mein', 'par',
        'batao', 'dikhao', 'karo', 'karein', 'chahiye', 'hoga', 'hogi', 'paas',
        'abhi', 'sabse', 'pehle', 'baad', 'dukan', 'dhoondo', 'de do',
        'kardo', 'haziri', 'chhutti', 'kaunsa', 'kaun'
    ];

    /**
     * Detect language from input text
     * Returns: 'hi' (Devanagari Hindi), 'hinglish' (Roman Hindi), or 'en' (English)
     */
    public function detectLanguage(string $text): string
    {
        $trimmed = trim($text);
        if (empty($trimmed)) {
            return 'en';
        }

        // Check for Devanagari Unicode Block (U+0900 to U+097F)
        if (preg_match('/[\x{0900}-\x{097F}]/u', $trimmed)) {
            return 'hi';
        }

        $lower = strtolower($trimmed);
        $words = preg_split('/[\s,\.\?!;:]+/', $lower, -1, PREG_SPLIT_NO_EMPTY);
        
        $hinglishHits = 0;
        foreach ($words as $word) {
            if (in_array($word, $this->hinglishTokens, true)) {
                $hinglishHits++;
            }
        }

        // If >= 1 Hinglish token or >= 15% of words are Hinglish
        if ($hinglishHits > 0 && (count($words) <= 3 || ($hinglishHits / count($words)) >= 0.15)) {
            return 'hinglish';
        }

        return 'en';
    }

    /**
     * Suggest voice TTS locale for detected language
     */
    public function getTtsLocale(string $languageCode): string
    {
        return match ($languageCode) {
            'hi' => 'hi-IN',
            'hinglish' => 'hi-IN',
            default => 'en-IN',
        };
    }
}
