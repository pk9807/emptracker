<?php

namespace App\AI\Services;

use App\AI\Contracts\AiAuditServiceInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use App\AI\Enums\DataSensitivity;
use App\AI\Exceptions\AiDisabledException;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Exceptions\AiValidationException;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class AiGateway
{
    protected ToolRegistry $toolRegistry;
    protected AiRouter $router;
    protected AiContextBuilder $contextBuilder;
    protected AiResponseValidator $responseValidator;
    protected AiAuditServiceInterface $auditService;
    protected AiPermissionService $permissionService;
    protected AiConfirmationService $confirmationService;
    protected AiDataSanitizer $sanitizer;
    protected ?AiTrainingPipelineService $trainingService;

    public function __construct(
        ToolRegistry $toolRegistry,
        AiRouter $router,
        AiContextBuilder $contextBuilder,
        AiResponseValidator $responseValidator,
        AiAuditServiceInterface $auditService,
        AiPermissionService $permissionService,
        AiConfirmationService $confirmationService,
        ?AiDataSanitizer $sanitizer = null,
        ?AiTrainingPipelineService $trainingService = null
    ) {
        $this->toolRegistry = $toolRegistry;
        $this->router = $router;
        $this->contextBuilder = $contextBuilder;
        $this->responseValidator = $responseValidator;
        $this->auditService = $auditService;
        $this->permissionService = $permissionService;
        $this->confirmationService = $confirmationService;
        $this->sanitizer = $sanitizer ?? new AiDataSanitizer();
        $this->trainingService = $trainingService ?? new AiTrainingPipelineService();
    }

    /**
     * Process an incoming conversational AI request through the Local-First Pipeline
     *
     * @param User $user Authenticated user
     * @param string $message User prompt
     * @param array $options Additional options (conversation_id, client_context, etc.)
     * @return AiResponse
     */
    public function handle(User $user, string $message, array $options = []): AiResponse
    {
        $start = microtime(true);

        // 1. Feature Flag Check
        if (!config('ai.enabled', true)) {
            throw new AiDisabledException();
        }

        // 2. Build Request DTO and sanitize input
        $sanitizedMessage = $this->contextBuilder->sanitizeInput($message);
        if (empty($sanitizedMessage)) {
            return AiResponse::error("Please provide a valid question or command.");
        }

        $request = AiRequest::create(
            user: $user,
            message: $sanitizedMessage,
            conversationId: $options['conversation_id'] ?? null,
            history: $options['history'] ?? [],
            clientContext: $options['client_context'] ?? [],
            localOnly: (bool)($options['local_only'] ?? false)
        );

        $toolResults = [];
        $toolsUsed = [];

        try {
            // 3. Intent Routing: Determine which tools to execute
            $toolCalls = $this->router->routeTools($request);

            // 4. Classify Privacy Tier
            $privacy = $this->router->classifyPrivacy($request, $toolCalls);

            // 5. Tool Execution Pipeline with strict authorization & resource isolation
            foreach ($toolCalls as $call) {
                $tool = $this->toolRegistry->getTool($call->toolName);
                if (!$tool) {
                    continue;
                }

                // Verify tool permission (Throws AiPermissionDeniedException if forbidden)
                $this->permissionService->authorizeTool($user, $tool);

                // --- 2-STEP CONFIRMATION GUARD FOR WRITE ACTIONS ---
                if ($tool->isWriteAction()) {
                    $summary = "Proposed {$tool->getName()} with parameters: " . json_encode($call->arguments);
                    $proposal = $this->confirmationService->createProposal(
                        user: $user,
                        tool: $tool,
                        parameters: $call->arguments,
                        summary: $summary,
                        impact: "Database record update for action '{$tool->getName()}'."
                    );

                    $confirmResponse = AiResponse::actionConfirmation(
                        message: "Action requires confirmation: {$summary}. Would you like to proceed?",
                        action: $tool->getName(),
                        pendingData: $proposal,
                        source: 'local_qwen_embedded',
                        toolsUsed: [$tool->getName()],
                        latencyMs: (microtime(true) - $start) * 1000
                    );

                    $this->auditService->logInteraction($request, $confirmResponse, [$tool->getName()]);
                    return $confirmResponse;
                }

                // Execute read-only tool
                $result = $tool->execute($user, $call->arguments);
                $toolResults[$tool->getName()] = $result->toArray();
                $toolsUsed[] = $tool->getName();
            }

            // 6. Select Provider (Local First -> Cloud Fallback)
            $provider = $this->router->selectProvider($request, $privacy, false);
            $routingLog = $this->router->getRoutingDecisionLog($request, $privacy, $provider->getIdentifier());

            // 7. Build Minimized Context Payload with PII Redaction
            $cleanToolResults = $this->sanitizer->redactPii($toolResults);
            $toolSchemas = $this->toolRegistry->getToolSchemasForUser($user);
            $context = $this->contextBuilder->buildPromptContext($request, $toolSchemas, $cleanToolResults);

            // 8. Generate Response
            $rawResponse = $provider->generate($request, $context);

            // 9. Attach Routing & Telemetry Metadata
            $metadata = array_merge($rawResponse->metadata, [
                'routing' => $routingLog,
                'privacy_tier' => $privacy->value,
            ]);

            $responseWithMeta = new AiResponse(
                type: $rawResponse->type,
                message: $rawResponse->message,
                source: $rawResponse->source,
                toolsUsed: $rawResponse->toolsUsed,
                requiresConfirmation: $rawResponse->requiresConfirmation,
                action: $rawResponse->action,
                data: $rawResponse->data,
                latencyMs: (microtime(true) - $start) * 1000,
                metadata: $metadata
            );

            // 10. Validate & Sanitize Response
            $finalResponse = $this->responseValidator->validate($responseWithMeta);

            // 11. Record Audit Log
            $this->auditService->logInteraction($request, $finalResponse, $toolsUsed);

            // 12. Continuous Local Model Training Dataset Collector
            $this->trainingService?->recordInteraction($request, $finalResponse);

            return $finalResponse;
        } catch (AiPermissionDeniedException $e) {
            $response = AiResponse::error($e->getMessage(), 'security_policy', (microtime(true) - $start) * 1000);
            $this->auditService->logInteraction($request, $response, $toolsUsed);
            return $response;
        } catch (\Throwable $e) {
            Log::error("AiGateway Exception: {$e->getMessage()}", ['trace' => $e->getTraceAsString()]);
            $response = AiResponse::error(
                "An error occurred while processing your request. Please try again.",
                'system',
                (microtime(true) - $start) * 1000
            );
            $this->auditService->logInteraction($request, $response, $toolsUsed);
            return $response;
        }
    }

    /**
     * Execute a confirmed write action with re-authorization, validation & transaction
     *
     * @param User $user Authenticated user
     * @param string $confirmationToken
     * @return array
     * @throws \Throwable
     */
    public function confirmAction(User $user, string $confirmationToken): array
    {
        $start = microtime(true);

        // 1. Verify token integrity, ownership, and idempotency
        $payload = $this->confirmationService->verifyToken($confirmationToken, $user);
        $actionName = $payload['action'];
        $parameters = $payload['parameters'];

        $tool = $this->toolRegistry->getTool($actionName);
        if (!$tool) {
            throw new AiValidationException("Tool '{$actionName}' is no longer available in the registry.");
        }

        // 2. Re-authorize User against Policy / Role
        $this->permissionService->authorizeTool($user, $tool);

        // 3. Execute Action within DB Transaction
        $result = $tool->execute($user, $parameters);

        // 4. Mark token as consumed (Idempotency Protection)
        $this->confirmationService->consumeToken($confirmationToken);

        // 5. Create Audit Log for Write Action
        $req = AiRequest::create(
            user: $user,
            message: "CONFIRMED ACTION EXECUTION: {$actionName}",
            clientContext: ['confirmation_token' => $confirmationToken]
        );
        $resp = AiResponse::answer(
            message: $result->data['message'] ?? 'Action executed successfully.',
            source: 'deterministic_write_tool',
            toolsUsed: [$actionName],
            data: $result->data,
            latencyMs: (microtime(true) - $start) * 1000
        );
        $this->auditService->logInteraction($req, $resp, [$actionName]);

        return [
            'success' => true,
            'action' => $actionName,
            'result' => $result->data,
            'message' => $result->data['message'] ?? 'Action executed successfully.',
            'latency_ms' => round((microtime(true) - $start) * 1000, 2),
        ];
    }

    /**
     * Cancel a proposed write action
     */
    public function cancelAction(User $user, string $confirmationToken): bool
    {
        return $this->confirmationService->cancelToken($confirmationToken, $user);
    }

}
