<?php

return [
    /*
    |--------------------------------------------------------------------------
    | EmpTracker AI Master Feature Flag
    |--------------------------------------------------------------------------
    | When set to false, all AI endpoints and background triggers are disabled.
    | Existing tracking, attendance, and shop management operate without change.
    */
    'enabled' => env('AI_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Local-First AI Engine Configuration
    |--------------------------------------------------------------------------
    | EmpTracker prioritizes on-device and local edge models (Qwen 2.5 / Gemma 2).
    */
    'local' => [
        'enabled' => env('AI_LOCAL_ENABLED', true),
        'model' => env('AI_LOCAL_MODEL', 'qwen2.5-1.5b-instruct-q4'),
        'max_context_tokens' => env('AI_MAX_CONTEXT_TOKENS', 2048),
        'temperature' => 0.2,
    ],

    /*
    |--------------------------------------------------------------------------
    | Cloud AI Fallback Configuration
    |--------------------------------------------------------------------------
    | Configurable cloud fallback provider (gemini, openai, or anthropic).
    | Sensitive operational data is blocked from cloud transmission.
    */
    'cloud' => [
        'enabled' => env('AI_CLOUD_FALLBACK_ENABLED', false),
        'provider' => env('AI_CLOUD_PROVIDER', 'gemini'),
        'model' => env('AI_CLOUD_MODEL', 'gemini-1.5-flash'),
        'api_key' => env('AI_CLOUD_API_KEY', ''),
        'timeout_seconds' => env('AI_CLOUD_TIMEOUT', 15),
    ],

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting & Safety Guardrails
    |--------------------------------------------------------------------------
    */
    'rate_limit' => [
        'max_requests_per_minute' => env('AI_RATE_LIMIT_PER_MINUTE', 30),
    ],

    /*
    |--------------------------------------------------------------------------
    | Voice & Multilingual Intelligence (Phase 6)
    |--------------------------------------------------------------------------
    */
    'voice' => [
        'enabled' => env('VOICE_AI_ENABLED', true),
        'input_enabled' => env('VOICE_INPUT_ENABLED', true),
        'output_enabled' => env('VOICE_OUTPUT_ENABLED', true),
        'default_tts_language' => env('AI_TTS_LANGUAGE', 'hi-IN'),
    ],

    'multilingual' => [
        'enabled' => env('MULTILINGUAL_AI_ENABLED', true),
        'default_language' => env('AI_DEFAULT_LANGUAGE', 'auto'),
        'supported_languages' => ['en', 'hi', 'hinglish'],
    ],

    'offline' => [
        'enabled' => env('OFFLINE_AI_ENABLED', true),
        'allow_cached_faq' => true,
        'stale_data_warning_minutes' => 15,
    ],

    /*
    |--------------------------------------------------------------------------
    | Proactive AI Intelligence, Alerts & Thresholds (Phase 7)
    |--------------------------------------------------------------------------
    */
    'proactive' => [
        'enabled' => env('PROACTIVE_AI_ENABLED', true),
        'idle_threshold_minutes' => (int)env('AI_IDLE_THRESHOLD_MINUTES', 30),
        'shop_overdue_days' => (int)env('AI_SHOP_OVERDUE_DAYS', 7),
        'route_deviation_threshold_km' => (float)env('AI_ROUTE_DEVIATION_KM', 2.0),
        'late_start_cutoff_time' => env('AI_LATE_START_CUTOFF', '10:30'),
        'deduplication_cooldown_hours' => (int)env('AI_DEDUP_COOLDOWN_HOURS', 6),
    ],
];
