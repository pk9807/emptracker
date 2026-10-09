<?php

namespace App\AI\Contracts;

use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;

interface AiProviderInterface
{
    /**
     * Unique provider identifier (e.g. 'local_qwen', 'cloud_gemini', 'cloud_openai')
     */
    public function getIdentifier(): string;

    /**
     * Whether this provider is available and ready to accept requests
     */
    public function isAvailable(): bool;

    /**
     * Generate response given an AI request and structured tool results context
     *
     * @param AiRequest $request
     * @param array $toolsContext Context payload containing available tools and tool execution outputs
     * @return AiResponse
     */
    public function generate(AiRequest $request, array $toolsContext = []): AiResponse;
}
