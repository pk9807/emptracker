<?php

namespace App\Http\Controllers\Api;

use App\AI\Services\AiTrainingPipelineService;
use App\AI\Services\WhisperTranscriptionService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiVoiceController extends Controller
{
    protected WhisperTranscriptionService $whisperService;
    protected AiTrainingPipelineService $trainingService;

    public function __construct(
        WhisperTranscriptionService $whisperService,
        AiTrainingPipelineService $trainingService
    ) {
        $this->whisperService = $whisperService;
        $this->trainingService = $trainingService;
    }

    /**
     * Transcribe incoming audio using Whisper (local / cloud fallback)
     */
    public function transcribe(Request $request): JsonResponse
    {
        $request->validate([
            'audio' => 'required|file|max:20480', // max 20MB
            'language' => 'nullable|string|in:auto,hi,en,hi-IN,en-US',
        ]);

        $audioFile = $request->file('audio');
        $language = $request->input('language', 'auto');

        $result = $this->whisperService->transcribe($audioFile, $language);

        return response()->json([
            'success' => !empty($result['text']),
            'transcription' => $result['text'] ?? '',
            'language' => $result['language'] ?? $language,
            'source' => $result['source'] ?? 'whisper',
        ]);
    }

    /**
     * Get continuous AI training dataset telemetry & stats
     */
    public function trainingStats(): JsonResponse
    {
        $stats = $this->trainingService->getStats();
        return response()->json([
            'success' => true,
            'stats' => $stats,
        ]);
    }
}
