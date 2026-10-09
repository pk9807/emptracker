<?php

namespace App\AI\Services;

use App\AI\Enums\DataSensitivity;

class AiModelRegistry
{
    /**
     * Get all registered models in the platform
     */
    public function getAllModels(): array
    {
        $localModelName = config('ai.local.model', 'qwen2.5-1.5b-instruct-q4');
        $cloudProvider = config('ai.cloud.provider', 'gemini');
        $cloudModelName = config('ai.cloud.model', 'gemini-1.5-flash');

        return [
            [
                'model_id' => 'qwen-2.5-1.5b-local',
                'provider' => 'local_qwen_embedded',
                'model_name' => $localModelName,
                'model_version' => '2.5',
                'type' => 'local',
                'capabilities' => ['text_generation', 'structured_json', 'multilingual_indic', 'offline_guidance'],
                'context_limit' => (int)config('ai.local.max_context_tokens', 2048),
                'language_support' => ['en', 'hi', 'hinglish'],
                'enabled' => (bool)config('ai.local.enabled', true),
                'fallback_priority' => 1,
                'privacy_class' => DataSensitivity::HIGHLY_SENSITIVE->value,
                'created_at' => '2026-10-08T00:00:00Z',
            ],
            [
                'model_id' => 'gemma-2-2b-local',
                'provider' => 'local_gemma_embedded',
                'model_name' => 'gemma-2-2b-it-q4',
                'model_version' => '2.0',
                'type' => 'local',
                'capabilities' => ['text_generation', 'structured_json', 'summarization'],
                'context_limit' => 2048,
                'language_support' => ['en', 'hi', 'hinglish'],
                'enabled' => false,
                'fallback_priority' => 2,
                'privacy_class' => DataSensitivity::HIGHLY_SENSITIVE->value,
                'created_at' => '2026-10-08T00:00:00Z',
            ],
            [
                'model_id' => 'cloud-primary-fallback',
                'provider' => $cloudProvider,
                'model_name' => $cloudModelName,
                'model_version' => '1.5',
                'type' => 'cloud',
                'capabilities' => ['complex_reasoning', 'long_context_synthesis', 'advanced_multilingual'],
                'context_limit' => 32768,
                'language_support' => ['en', 'hi', 'hinglish', 'mr', 'ta'],
                'enabled' => (bool)config('ai.cloud.enabled', false),
                'fallback_priority' => 3,
                'privacy_class' => DataSensitivity::INTERNAL->value, // Cloud only allowed for INTERNAL or PUBLIC data
                'created_at' => '2026-10-08T00:00:00Z',
            ],
        ];
    }

    /**
     * Get active local inference model
     */
    public function getActiveLocalModel(): ?array
    {
        $models = $this->getAllModels();
        foreach ($models as $m) {
            if ($m['type'] === 'local' && $m['enabled']) {
                return $m;
            }
        }
        return null;
    }

    /**
     * Get active cloud fallback model
     */
    public function getActiveCloudModel(): ?array
    {
        $models = $this->getAllModels();
        foreach ($models as $m) {
            if ($m['type'] === 'cloud' && $m['enabled']) {
                return $m;
            }
        }
        return null;
    }

    /**
     * Retrieve model by ID
     */
    public function getModel(string $modelId): ?array
    {
        foreach ($this->getAllModels() as $m) {
            if ($m['model_id'] === $modelId) {
                return $m;
            }
        }
        return null;
    }
}
