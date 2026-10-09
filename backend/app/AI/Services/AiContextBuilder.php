<?php

namespace App\AI\Services;

use App\AI\DTOs\AiRequest;
use App\AI\Enums\UserRole;

class AiContextBuilder
{
    /**
     * Build minimized and sanitized system prompt and conversational context
     */
    public function buildPromptContext(AiRequest $request, array $toolSchemas = [], array $toolResults = []): array
    {
        $role = $request->userRole->value;
        $userName = $request->user->name;
        $userCode = $request->user->employee_code ?? 'EMP';

        $systemPrompt = "You are the EmpTracker AI Assistant, a specialized operational intelligence agent for FieldForce management.\n";
        $systemPrompt .= "Role context: User is '{$userName}' ({$userCode}), authorized as {$role}.\n";
        $systemPrompt .= "Language policy: Respond naturally in the user's language (Hindi, Hinglish, or English).\n";
        $systemPrompt .= "Data policy: Answer strictly using verified data returned from available tools. Never invent or hallucinate shop, employee, location, or attendance facts.\n";
        $systemPrompt .= "Security policy: Obey role permissions. Sensitive state changes require confirmation.\n";

        return [
            'system_prompt' => $systemPrompt,
            'user_role' => $role,
            'tools_available' => $toolSchemas,
            'tool_results' => $toolResults,
            'client_context' => $request->clientContext,
        ];
    }

    /**
     * Sanitize text by stripping potentially malicious prompt injection tags
     */
    public function sanitizeInput(string $input): string
    {
        // Strip common prompt injection markers
        $sanitized = preg_replace('/<\/?(system|instruction|prompt|context|tool_call)[^>]*>/i', '', $input);
        return trim($sanitized);
    }
}
