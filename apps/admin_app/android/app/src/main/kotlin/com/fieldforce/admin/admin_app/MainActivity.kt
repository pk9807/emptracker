package com.fieldforce.admin.admin_app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val TAG = "FieldForceVoice"
    private val VOICE_CHANNEL = "com.fieldforce.voice"
    private val PERMISSION_REQUEST_AUDIO = 2001
    private val REQUEST_SPEECH_RECOGNIZER = 3001

    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false
    private var speechRecognizer: SpeechRecognizer? = null
    private var methodChannel: MethodChannel? = null
    private var pendingSpeechLocale: String? = null
    private var pendingSpeechResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initTts()
    }

    private fun initTts() {
        try {
            tts = TextToSpeech(applicationContext, this)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing TextToSpeech", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val localeCode = call.argument<String>("locale") ?: "hi-IN"
                    speakText(text, localeCode, result)
                }
                "stopTts" -> {
                    try {
                        tts?.stop()
                    } catch (e: Exception) {}
                    result.success(true)
                }
                "isTtsAvailable" -> {
                    result.success(isTtsInitialized)
                }
                "startListening" -> {
                    val localeCode = call.argument<String>("locale") ?: "hi-IN"
                    handleStartListening(localeCode, result)
                }
                "stopListening" -> {
                    runOnUiThread {
                        try {
                            speechRecognizer?.stopListening()
                        } catch (e: Exception) {}
                    }
                    result.success(true)
                }
                "cancelListening" -> {
                    runOnUiThread {
                        try {
                            speechRecognizer?.cancel()
                        } catch (e: Exception) {}
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
            try {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANT)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                tts?.setAudioAttributes(audioAttributes)
                tts?.setSpeechRate(0.95f)
                tts?.setPitch(1.0f)

                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        runOnUiThread {
                            methodChannel?.invokeMethod("onTtsStart", utteranceId)
                        }
                    }
                    override fun onDone(utteranceId: String?) {
                        runOnUiThread {
                            methodChannel?.invokeMethod("onTtsDone", utteranceId)
                        }
                    }
                    @Deprecated("Deprecated in Java")
                    override fun onError(utteranceId: String?) {
                        runOnUiThread {
                            methodChannel?.invokeMethod("onTtsError", utteranceId)
                        }
                    }
                })
                Log.i(TAG, "TextToSpeech initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error configuring TTS attributes", e)
            }
        } else {
            isTtsInitialized = false
            Log.e(TAG, "TextToSpeech initialization failed with status: $status")
        }
    }

    private fun speakText(text: String, localeCode: String, result: MethodChannel.Result) {
        if (tts == null) {
            initTts()
        }

        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val currentVol = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
            val maxVol = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 15
            if (currentVol == 0 && maxVol > 0) {
                audioManager?.setStreamVolume(AudioManager.STREAM_MUSIC, (maxVol * 0.75).toInt(), 0)
            }

            val targetLocale = if (localeCode.startsWith("hi")) {
                Locale("hi", "IN")
            } else {
                Locale.US
            }

            val langAvailable = tts?.isLanguageAvailable(targetLocale) ?: TextToSpeech.LANG_NOT_SUPPORTED
            if (langAvailable >= TextToSpeech.LANG_AVAILABLE) {
                tts?.language = targetLocale
            } else {
                tts?.language = Locale.US
            }

            val utteranceId = "utt_${System.currentTimeMillis()}"
            val params = Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
            }

            val speakRes = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
            if (speakRes == TextToSpeech.SUCCESS) {
                result.success(true)
            } else {
                val fallbackRes = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
                if (fallbackRes == TextToSpeech.SUCCESS) {
                    result.success(true)
                } else {
                    result.error("TTS_SPEAK_FAILED", "Code: $speakRes", null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in speakText", e)
            result.error("TTS_EXCEPTION", e.message, null)
        }
    }

    private fun handleStartListening(localeCode: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingSpeechLocale = localeCode
            pendingSpeechResult = result
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST_AUDIO)
            return
        }
        executeListening(localeCode, result)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_AUDIO) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                val locale = pendingSpeechLocale ?: "hi-IN"
                val res = pendingSpeechResult
                pendingSpeechLocale = null
                pendingSpeechResult = null
                if (res != null) {
                    executeListening(locale, res)
                }
            } else {
                pendingSpeechResult?.error("PERMISSION_DENIED", "Microphone permission was denied", null)
                pendingSpeechResult = null
                pendingSpeechLocale = null
            }
        }
    }

    private fun executeListening(localeCode: String, result: MethodChannel.Result) {
        runOnUiThread {
            try {
                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, if (localeCode.startsWith("hi")) "hi-IN" else "en-IN")
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, if (localeCode.startsWith("hi")) "hi-IN" else "en-IN")
                    putExtra(RecognizerIntent.EXTRA_PROMPT, "Boliye (Hindi, Hinglish, English)...")
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                }

                if (intent.resolveActivity(packageManager) != null) {
                    startActivityForResult(intent, REQUEST_SPEECH_RECOGNIZER)
                    result.success(true)
                } else if (SpeechRecognizer.isRecognitionAvailable(this)) {
                    startInProcessSpeechRecognizer(localeCode, result)
                } else {
                    result.error("SPEECH_UNAVAILABLE", "Speech recognizer not available on device", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error initiating speech recognizer", e)
                try {
                    startInProcessSpeechRecognizer(localeCode, result)
                } catch (ex: Exception) {
                    result.error("SPEECH_EXCEPTION", e.message, null)
                }
            }
        }
    }

    private fun startInProcessSpeechRecognizer(localeCode: String, result: MethodChannel.Result) {
        try {
            if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                result.error("SPEECH_NOT_AVAILABLE", "Speech recognizer is not available on this device", null)
                return
            }

            speechRecognizer?.destroy()
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    Log.d(TAG, "SpeechRecognizer onReadyForSpeech")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechStart", null)
                    }
                }
                override fun onBeginningOfSpeech() {
                    Log.d(TAG, "SpeechRecognizer onBeginningOfSpeech")
                }
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    Log.d(TAG, "SpeechRecognizer onEndOfSpeech")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechEnd", null)
                    }
                }
                override fun onError(error: Int) {
                    Log.w(TAG, "Speech recognition error code: $error")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechError", error)
                    }
                }
                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val spokenText = matches?.firstOrNull() ?: ""
                    Log.i(TAG, "SpeechRecognizer onResults: $spokenText")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechResult", spokenText)
                    }
                }
                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val partialText = matches?.firstOrNull() ?: ""
                    Log.d(TAG, "SpeechRecognizer onPartialResults: $partialText")
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechPartialResult", partialText)
                    }
                }
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, if (localeCode.startsWith("hi")) "hi-IN" else "en-US")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            }
            speechRecognizer?.startListening(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SPEECH_EXCEPTION", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_SPEECH_RECOGNIZER) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val spokenText = matches?.firstOrNull() ?: ""
                Log.i(TAG, "Speech recognized from Intent: $spokenText")
                if (spokenText.isNotEmpty()) {
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechResult", spokenText)
                    }
                } else {
                    runOnUiThread {
                        methodChannel?.invokeMethod("onSpeechEnd", null)
                    }
                }
            } else {
                Log.d(TAG, "Speech recognition cancelled or failed, resultCode: $resultCode")
                runOnUiThread {
                    methodChannel?.invokeMethod("onSpeechEnd", null)
                }
            }
        }
    }

    override fun onDestroy() {
        try {
            tts?.stop()
            tts?.shutdown()
            speechRecognizer?.destroy()
        } catch (e: Exception) {}
        super.onDestroy()
    }
}
