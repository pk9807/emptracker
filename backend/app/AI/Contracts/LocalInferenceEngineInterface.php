<?php

namespace App\AI\Contracts;

use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;

interface LocalInferenceEngineInterface
{
    /**
     * Unique identifier for the local engine runtime (e.g., 'qwen2.5-1.5b-instruct-q4')
     */
    public function getEngineName(): string;

    /**
     * Check if the local model runtime is ready, memory-loaded, and healthy
     */
    public function isAvailable(): bool;

    /**
     * Generate natural language response text
     *
     * @param string $prompt Formatted prompt with system instructions
     * @param array $options Generation parameters (temperature, max_tokens, stop_words)
     * @return string
     */
    public function generateText(string $prompt, array $options = []): string;

    /**
     * Generate guaranteed structured JSON output adhering to a schema
     *
     * @param string $prompt
     * @param array $jsonSchema
     * @param array $options
     * @return array
     */
    public function generateStructuredJson(string $prompt, array $jsonSchema, array $options = []): array;

    /**
     * Return runtime hardware telemetry (memory usage, device acceleration state)
     */
    public function getRuntimeMetrics(): array;
}
