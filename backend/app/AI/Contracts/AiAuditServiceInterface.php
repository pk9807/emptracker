<?php

namespace App\AI\Contracts;

use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;

interface AiAuditServiceInterface
{
    /**
     * Log an AI interaction for security, auditability, and telemetry
     */
    public function logInteraction(AiRequest $request, AiResponse $response, array $toolsExecuted = []): void;
}
