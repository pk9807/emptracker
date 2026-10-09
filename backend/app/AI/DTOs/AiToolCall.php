<?php

namespace App\AI\DTOs;

class AiToolCall
{
    public function __construct(
        public readonly string $toolName,
        public readonly array $arguments = []
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            toolName: $data['tool_name'] ?? $data['name'] ?? '',
            arguments: $data['arguments'] ?? $data['parameters'] ?? []
        );
    }

    public function toArray(): array
    {
        return [
            'tool_name' => $this->toolName,
            'arguments' => $this->arguments,
        ];
    }
}
