# EmpTracker Voice Intelligence & Audio Privacy Architecture

## 1. Executive Principles

1. **User-Initiated Audio Stream:** Microphones are activated exclusively upon explicit physical interaction (tap of microphone button). Continuous background listening is strictly forbidden.
2. **On-Device First STT & TTS:** Speech recognition and speech synthesis use on-device local engines without raw audio egress to third-party cloud servers.
3. **Voice Safety For Write Actions:** A spoken voice prompt (e.g. *"Ravi ko Z Square Mall assign kar do"*) will **propose** an action card, but will **NEVER** confirm it automatically. The authenticated human operator must physically confirm via the Phase 4 interactive cryptographic confirmation card. Spoken confirmations are explicitly rejected.

---

## 2. Voice Pipeline Architecture

```
[ User Taps Mic Button ]
          │
          ▼
[ Microphone Permission Check ]
          │
          ▼
[ On-Device Speech Recognition ] (SpeechRecognitionProvider)
          │
          ▼
[ Language & Script Detection ] (AiLanguageDetector: hi / hinglish / en)
          │
          ▼
[ AI Gateway Intent Routing ] ───> [ Deterministic Tool Engine ]
          │
          ▼
[ Structured Natural Language Response ]
          │
          ▼
[ Optional On-Device TTS Output ] (TextToSpeechProvider: hi-IN / en-IN)
```

---

## 3. Supported Voice Locales
- **Hindi (Devanagari):** `hi-IN`
- **Hinglish (Roman Hindi):** `hi-IN` / `en-IN`
- **English (Indian):** `en-IN`
