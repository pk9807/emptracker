<?php

namespace App\AI\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhisperTranscriptionService
{
    protected string $whisperBinary;
    protected ?string $openaiApiKey;
    protected string $whisperModelPath;

    public function __construct()
    {
        $this->whisperBinary = config('ai.whisper.binary', '/usr/bin/whisper');
        $this->openaiApiKey = config('ai.cloud.api_key') ?? env('OPENAI_API_KEY');
        $this->whisperModelPath = config('ai.whisper.model_path', storage_path('ai_models/whisper-small.bin'));
    }

    /**
     * Transcribe audio file using Local Whisper or Cloud Fallback
     */
    public function transcribe(UploadedFile $audioFile, string $language = 'auto'): array
    {
        $filePath = $audioFile->getRealPath();

        // 1. Attempt Local Whisper if binary / model exists
        if (file_exists($this->whisperBinary) && file_exists($this->whisperModelPath)) {
            $localResult = $this->transcribeLocally($filePath, $language);
            if (!empty($localResult['text'])) {
                return $localResult;
            }
        }

        // 2. Cloud Whisper Fallback if API key configured
        if (!empty($this->openaiApiKey)) {
            $cloudResult = $this->transcribeCloud($audioFile, $language);
            if (!empty($cloudResult['text'])) {
                return $cloudResult;
            }
        }

        // 3. Graceful heuristic / simulation fallback
        return [
            'text' => '',
            'language' => $language,
            'source' => 'whisper_offline_fallback',
            'duration' => 0.0,
        ];
    }

    /**
     * Transcribe locally via whisper CLI
     */
    protected function transcribeLocally(string $audioPath, string $language): array
    {
        try {
            $langArg = ($language === 'hi') ? '--language hi' : '--language auto';
            $cmd = escapeshellcmd("{$this->whisperBinary} --model {$this->whisperModelPath} {$langArg} --output_format txt --output_dir /tmp {$audioPath}");
            $output = shell_exec($cmd);

            $txtFile = '/tmp/' . pathinfo($audioPath, PATHINFO_FILENAME) . '.txt';
            $text = file_exists($txtFile) ? trim(file_get_contents($txtFile)) : trim($output ?? '');
            @unlink($txtFile);

            return [
                'text' => $text,
                'language' => $language,
                'source' => 'whisper_local',
                'duration' => 0.0,
            ];
        } catch (\Throwable $e) {
            Log::warning('Local whisper transcription failed: ' . $e->getMessage());
            return ['text' => ''];
        }
    }

    /**
     * Transcribe via Whisper API
     */
    protected function transcribeCloud(UploadedFile $audioFile, string $language): array
    {
        try {
            $response = Http::withToken($this->openaiApiKey)
                ->timeout(15)
                ->attach('file', file_get_contents($audioFile->getRealPath()), $audioFile->getClientOriginalName())
                ->post('https://api.openai.com/v1/audio/transcriptions', [
                    'model' => 'whisper-1',
                    'language' => ($language === 'hi' || $language === 'hi-IN') ? 'hi' : null,
                ]);

            if ($response->successful()) {
                $data = $response->json();
                return [
                    'text' => trim($data['text'] ?? ''),
                    'language' => $language,
                    'source' => 'whisper_cloud',
                    'duration' => 0.0,
                ];
            }
        } catch (\Throwable $e) {
            Log::warning('Cloud whisper transcription failed: ' . $e->getMessage());
        }

        return ['text' => ''];
    }
}
