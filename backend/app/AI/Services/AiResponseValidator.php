<?php

namespace App\AI\Services;

use App\AI\DTOs\AiResponse;

class AiResponseValidator
{
    /**
     * Validate the response output to ensure it matches safety and structure requirements
     */
    public function validate(AiResponse $response): AiResponse
    {
        // 1. Ensure message is non-empty
        $message = trim($response->message);
        if (empty($message)) {
            return AiResponse::error("Received empty response from AI engine", $response->source);
        }

        // 2. Mask any accidentally exposed database credentials or API keys
        $maskedMessage = preg_replace(
            '/(password|token|secret|key|sanctum|bearer)\s*[:=]\s*[^\s,]+/i',
            '$1: [REDACTED]',
            $message
        );

        // 3. Ensure no raw SQL statements leaked in message
        if (preg_match('/(SELECT\s+.*FROM|INSERT\s+INTO|UPDATE\s+.*SET|DELETE\s+FROM)/i', $maskedMessage)) {
            $maskedMessage = "Operation completed using verified application tools.";
        }

        if ($maskedMessage !== $message) {
            return new AiResponse(
                type: $response->type,
                message: $maskedMessage,
                source: $response->source,
                toolsUsed: $response->toolsUsed,
                requiresConfirmation: $response->requiresConfirmation,
                action: $response->action,
                data: $response->data,
                latencyMs: $response->latencyMs,
                metadata: $response->metadata
            );
        }

        return $response;
    }

    /**
     * Validate a structured JSON payload against expected schema keys
     */
    public function validateJsonSchema(array $payload, array $requiredKeys): bool
    {
        foreach ($requiredKeys as $key) {
            if (!array_key_exists($key, $payload)) {
                return false;
            }
        }
        return true;
    }
}
