<?php

namespace App\AI\DTOs;

use App\AI\Enums\ResponseType;

class AiResponse
{
    public function __construct(
        public readonly ResponseType $type,
        public readonly string $message,
        public readonly string $source, // 'local_ai', 'deterministic_tools', 'cloud_ai', 'system'
        public readonly array $toolsUsed = [],
        public readonly bool $requiresConfirmation = false,
        public readonly ?string $action = null,
        public readonly mixed $data = null,
        public readonly float $latencyMs = 0.0,
        public readonly array $metadata = []
    ) {}

    public static function answer(
        string $message,
        string $source = 'local_ai',
        array $toolsUsed = [],
        mixed $data = null,
        float $latencyMs = 0.0,
        array $metadata = []
    ): self {
        return new self(
            type: ResponseType::ANSWER,
            message: $message,
            source: $source,
            toolsUsed: $toolsUsed,
            requiresConfirmation: false,
            action: null,
            data: $data,
            latencyMs: $latencyMs,
            metadata: $metadata
        );
    }

    public static function actionConfirmation(
        string $message,
        string $action,
        mixed $pendingData = null,
        string $source = 'deterministic_tools',
        array $toolsUsed = [],
        float $latencyMs = 0.0
    ): self {
        return new self(
            type: ResponseType::ACTION_CONFIRMATION,
            message: $message,
            source: $source,
            toolsUsed: $toolsUsed,
            requiresConfirmation: true,
            action: $action,
            data: $pendingData,
            latencyMs: $latencyMs
        );
    }

    public static function error(
        string $message,
        string $source = 'system',
        float $latencyMs = 0.0,
        array $metadata = []
    ): self {
        return new self(
            type: ResponseType::ERROR,
            message: $message,
            source: $source,
            toolsUsed: [],
            requiresConfirmation: false,
            action: null,
            data: null,
            latencyMs: $latencyMs,
            metadata: $metadata
        );
    }

    public function toArray(): array
    {
        return [
            'type' => $this->type->value,
            'message' => $this->message,
            'source' => $this->source,
            'tools_used' => $this->toolsUsed,
            'requires_confirmation' => $this->requiresConfirmation,
            'action' => $this->action,
            'data' => $this->data,
            'latency_ms' => round($this->latencyMs, 2),
            'metadata' => $this->metadata,
        ];
    }
}
