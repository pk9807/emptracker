<?php

namespace App\AI\DTOs;

class AiToolResult
{
    public function __construct(
        public readonly string $toolName,
        public readonly bool $isSuccess,
        public readonly mixed $data = null,
        public readonly ?string $errorMessage = null,
        public readonly float $executionTimeMs = 0.0,
        public readonly bool $requiresConfirmation = false,
        public readonly ?string $confirmationPrompt = null
    ) {}

    public static function success(string $toolName, mixed $data, float $executionTimeMs = 0.0): self
    {
        return new self(
            toolName: $toolName,
            isSuccess: true,
            data: $data,
            errorMessage: null,
            executionTimeMs: $executionTimeMs
        );
    }

    public static function failure(string $toolName, string $errorMessage, float $executionTimeMs = 0.0): self
    {
        return new self(
            toolName: $toolName,
            isSuccess: false,
            data: null,
            errorMessage: $errorMessage,
            executionTimeMs: $executionTimeMs
        );
    }

    public static function confirmationRequired(string $toolName, string $prompt, mixed $pendingData = null): self
    {
        return new self(
            toolName: $toolName,
            isSuccess: true,
            data: $pendingData,
            errorMessage: null,
            requiresConfirmation: true,
            confirmationPrompt: $prompt
        );
    }

    public function toArray(): array
    {
        return [
            'tool_name' => $this->toolName,
            'is_success' => $this->isSuccess,
            'data' => $this->data,
            'error' => $this->errorMessage,
            'execution_time_ms' => $this->executionTimeMs,
            'requires_confirmation' => $this->requiresConfirmation,
            'confirmation_prompt' => $this->confirmationPrompt,
        ];
    }
}
