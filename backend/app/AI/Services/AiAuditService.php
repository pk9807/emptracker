<?php

namespace App\AI\Services;

use App\AI\Contracts\AiAuditServiceInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class AiAuditService implements AiAuditServiceInterface
{
    public function logInteraction(AiRequest $request, AiResponse $response, array $toolsExecuted = []): void
    {
        $logData = [
            'user_id' => $request->user->id,
            'user_role' => $request->userRole->value,
            'source' => $response->source,
            'response_type' => $response->type->value,
            'tools_used' => json_encode($response->toolsUsed),
            'requires_confirmation' => $response->requiresConfirmation ? 1 : 0,
            'action' => $response->action,
            'latency_ms' => $response->latencyMs,
            'created_at' => now(),
        ];

        try {
            if (Schema::hasTable('ai_audit_logs')) {
                DB::table('ai_audit_logs')->insert($logData);
            } else {
                Log::channel('daily')->info('AI_AUDIT', $logData);
            }
        } catch (\Throwable $e) {
            Log::warning("Failed to record AI audit log: {$e->getMessage()}", $logData);
        }
    }
}
