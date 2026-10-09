<?php

namespace App\AI\Services;

use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;

class AiTrainingPipelineService
{
    protected string $storagePath;
    protected string $datasetFile;

    public function __construct()
    {
        $this->storagePath = storage_path('ai_training');
        $this->datasetFile = $this->storagePath . '/training_dataset.jsonl';
        $this->ensureStorageDirectoryExists();
    }

    protected function ensureStorageDirectoryExists(): void
    {
        if (!File::exists($this->storagePath)) {
            File::makeDirectory($this->storagePath, 0755, true, true);
        }
    }

    /**
     * Record an AI interaction into the continuous training dataset
     */
    public function recordInteraction(AiRequest $request, AiResponse $response, array $metadata = []): void
    {
        try {
            // Only record valid completed responses
            if (empty($response->text) || empty($request->prompt)) {
                return;
            }

            $sanitizedPrompt = $this->sanitizeForTraining($request->prompt);
            $sanitizedResponse = $this->sanitizeForTraining($response->text);

            $entry = [
                'id' => uniqid('train_', true),
                'timestamp' => now()->toIso8601String(),
                'source' => $response->source,
                'language' => $metadata['language'] ?? 'mixed',
                'instruction' => 'You are EmpTracker Assistant, an enterprise field workforce AI for employee tracking, shop attendance, and live route intelligence in Hindi, Hinglish, and English.',
                'input' => $sanitizedPrompt,
                'output' => $sanitizedResponse,
                'tools_used' => array_map(fn($t) => $t->name, $response->toolCalls),
                'confidence' => $response->confidence,
                'feedback' => $metadata['feedback'] ?? 'neutral', // good, bad, neutral
            ];

            $jsonLine = json_encode($entry, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n";
            File::append($this->datasetFile, $jsonLine);
        } catch (\Throwable $e) {
            Log::warning('Failed to record AI training interaction: ' . $e->getMessage());
        }
    }

    /**
     * Sanitize PII and sensitive credentials from training pairs
     */
    protected function sanitizeForTraining(string $text): string
    {
        // Mask mobile phone numbers
        $text = preg_replace('/(\+91[\-\s]?)?[6-9]\d{9}/', '[PHONE_REDACTED]', $text);
        
        // Mask bearer tokens and API keys
        $text = preg_replace('/Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*/i', 'Bearer [TOKEN_REDACTED]', $text);
        
        // Mask passwords
        $text = preg_replace('/"password"\s*:\s*"[^"]+"/i', '"password":"[REDACTED]"', $text);

        return trim($text);
    }

    /**
     * Export the dataset in Alpaca / ShareGPT / LoRA format
     */
    public function exportDataset(string $format = 'alpaca', ?string $targetFile = null): string
    {
        $targetFile = $targetFile ?? ($this->storagePath . "/export_{$format}_" . date('Ymd_His') . '.jsonl');

        if (!File::exists($this->datasetFile)) {
            return '';
        }

        $lines = file($this->datasetFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $outputHandle = fopen($targetFile, 'w');

        foreach ($lines as $line) {
            $data = json_decode($line, true);
            if (!$data) continue;

            if ($format === 'sharegpt') {
                $item = [
                    'conversations' => [
                        ['from' => 'human', 'value' => $data['input']],
                        ['from' => 'gpt', 'value' => $data['output']],
                    ],
                    'system' => $data['instruction'],
                ];
            } else {
                // Default Alpaca / Instruct format
                $item = [
                    'instruction' => $data['instruction'],
                    'input' => $data['input'],
                    'output' => $data['output'],
                ];
            }

            fwrite($outputHandle, json_encode($item, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . "\n");
        }

        fclose($outputHandle);
        return $targetFile;
    }

    /**
     * Get dataset statistics
     */
    public function getStats(): array
    {
        if (!File::exists($this->datasetFile)) {
            return [
                'total_samples' => 0,
                'file_size_bytes' => 0,
                'last_updated' => null,
            ];
        }

        $lines = count(file($this->datasetFile, FILE_SKIP_EMPTY_LINES));
        return [
            'total_samples' => $lines,
            'file_size_bytes' => filesize($this->datasetFile),
            'last_updated' => date('c', filemtime($this->datasetFile)),
        ];
    }
}
