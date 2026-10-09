<?php

namespace App\AI\Providers;

use App\AI\Contracts\AiProviderInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CloudAiProvider implements AiProviderInterface
{
    public function getIdentifier(): string
    {
        return 'cloud_ai_fallback';
    }

    public function isAvailable(): bool
    {
        $enabled = config('ai.cloud.enabled', false);
        $apiKey = config('ai.cloud.api_key', '');
        return $enabled && !empty($apiKey);
    }

    public function generate(AiRequest $request, array $toolsContext = []): AiResponse
    {
        $start = microtime(true);

        if (!$this->isAvailable()) {
            return AiResponse::error("Cloud AI fallback is not configured or disabled.", $this->getIdentifier());
        }

        // Privacy check: Highly sensitive data is NEVER sent to Cloud AI
        if (!$request->privacyClassification->isCloudAllowed()) {
            return AiResponse::error(
                "Request contains sensitive operational data which is prohibited from cloud transmission.",
                $this->getIdentifier()
            );
        }

        $provider = config('ai.cloud.provider', 'gemini');
        $apiKey = config('ai.cloud.api_key');
        $model = config('ai.cloud.model', 'gemini-1.5-flash');

        try {
            $prompt = $this->buildCloudPrompt($request, $toolsContext);

            // Mockable / extensible external HTTP request
            $response = Http::timeout(15)->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}", [
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $prompt]
                        ]
                    ]
                ]
            ]);

            $latency = (microtime(true) - $start) * 1000;

            if ($response->successful()) {
                $body = $response->json();
                $text = $body['candidates'][0]['content']['parts'][0]['text'] ?? 'Response generated successfully.';
                return AiResponse::answer(
                    message: trim($text),
                    source: "cloud_{$provider}",
                    toolsUsed: array_keys($toolsContext['tool_results'] ?? []),
                    data: $toolsContext['tool_results'] ?? null,
                    latencyMs: $latency
                );
            }

            Log::warning("Cloud AI request failed with status: {$response->status()}", [
                'body' => $response->body()
            ]);

            return AiResponse::error("Cloud AI service responded with error: {$response->status()}", $this->getIdentifier());
        } catch (\Throwable $e) {
            $latency = (microtime(true) - $start) * 1000;
            Log::error("Cloud AI Exception: {$e->getMessage()}");
            return AiResponse::error("Cloud AI connection error: {$e->getMessage()}", $this->getIdentifier(), $latency);
        }
    }

    private function buildCloudPrompt(AiRequest $request, array $toolsContext): string
    {
        $role = $request->userRole->value;
        $context = json_encode($toolsContext['tool_results'] ?? []);

        return "You are EmpTracker AI assistant.\nRole: {$role}\nUser Query: {$request->message}\nVerified Backend Data: {$context}\nPlease provide a concise, helpful response.";
    }
}
