<?php

namespace App\Http\Controllers\Api;

use App\AI\Exceptions\AiDisabledException;
use App\AI\Services\AiGateway;
use App\AI\Services\ToolRegistry;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AiController extends Controller
{
    protected AiGateway $gateway;
    protected ToolRegistry $toolRegistry;

    public function __construct(AiGateway $gateway, ToolRegistry $toolRegistry)
    {
        $this->gateway = $gateway;
        $this->toolRegistry = $toolRegistry;
    }

    /**
     * Process an AI conversational query
     * POST /api/ai/chat
     */
    public function chat(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'message' => 'required|string|max:1000',
            'conversation_id' => 'nullable|string|max:100',
            'client_context' => 'nullable|array',
            'client_context.latitude' => 'nullable|numeric',
            'client_context.longitude' => 'nullable|numeric',
            'local_only' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->user();
            $response = $this->gateway->handle(
                user: $user,
                message: $request->input('message'),
                options: [
                    'conversation_id' => $request->input('conversation_id'),
                    'client_context' => $request->input('client_context', []),
                    'local_only' => (bool)$request->input('local_only', false),
                ]
            );

            return response()->json([
                'status' => 'success',
                'data' => $response->toArray(),
            ]);
        } catch (AiDisabledException $e) {
            return response()->json([
                'status' => 'disabled',
                'message' => $e->getMessage(),
            ], 503);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'AI service encountered an unexpected error.',
            ], 500);
        }
    }

    /**
     * Confirm and execute a 2-step write action
     * POST /api/ai/actions/confirm
     */
    public function confirmAction(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'confirmation_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->user();
            $result = $this->gateway->confirmAction($user, $request->input('confirmation_token'));

            return response()->json([
                'status' => 'success',
                'data' => $result,
            ]);
        } catch (\App\AI\Exceptions\AiPermissionDeniedException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 403);
        } catch (\App\AI\Exceptions\AiValidationException $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 422);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to execute confirmed action: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Cancel an action proposal
     * POST /api/ai/actions/cancel
     */
    public function cancelAction(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'confirmation_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $cancelled = $this->gateway->cancelAction($user, $request->input('confirmation_token'));

        return response()->json([
            'status' => 'success',
            'message' => $cancelled ? 'Action proposal successfully cancelled.' : 'Token not found or already expired.',
        ]);
    }

    /**
     * Introspect tools accessible to the authenticated user
     * GET /api/ai/tools
     */
    public function tools(Request $request): JsonResponse
    {
        $user = $request->user();
        $schemas = $this->toolRegistry->getToolSchemasForUser($user);

        return response()->json([
            'status' => 'success',
            'data' => [
                'user_role' => $user->role,
                'total_tools' => count($schemas),
                'tools' => $schemas,
            ],
        ]);
    }

    /**
     * AI Health and configuration status
     * GET /api/ai/health
     */
    public function health(): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'ai_enabled' => (bool)config('ai.enabled', true),
                'local_ai' => [
                    'enabled' => (bool)config('ai.local.enabled', true),
                    'model' => config('ai.local.model'),
                ],
                'cloud_fallback' => [
                    'enabled' => (bool)config('ai.cloud.enabled', false),
                    'provider' => config('ai.cloud.provider'),
                ],
                'voice' => [
                    'enabled' => (bool)config('ai.voice.enabled', true),
                    'input_enabled' => (bool)config('ai.voice.input_enabled', true),
                    'output_enabled' => (bool)config('ai.voice.output_enabled', true),
                    'default_tts_language' => config('ai.voice.default_tts_language', 'hi-IN'),
                ],
                'multilingual' => [
                    'enabled' => (bool)config('ai.multilingual.enabled', true),
                    'supported_languages' => config('ai.multilingual.supported_languages', ['en', 'hi', 'hinglish']),
                ],
                'offline' => [
                    'enabled' => (bool)config('ai.offline.enabled', true),
                ],
            ],
        ]);
    }

    /**
     * Introspect offline capability matrix
     * GET /api/ai/offline/matrix
     */
    public function offlineMatrix(\App\AI\Services\OfflineCapabilityService $capabilityService): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'matrix' => $capabilityService->getMatrix(),
            ],
        ]);
    }

    /**
     * Fetch active proactive insights for authenticated user
     * GET /api/ai/insights
     */
    public function insights(Request $request, \App\AI\Services\AiInsightEngine $insightEngine): JsonResponse
    {
        $user = $request->user();
        $insights = $insightEngine->getActiveInsights($user);

        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => $user->name,
                'role' => $user->role,
                'total_insights' => count($insights),
                'insights' => $insights,
            ],
        ]);
    }

    /**
     * Fetch executive daily operational summary (Admin only)
     * GET /api/ai/insights/summary
     */
    public function executiveSummary(Request $request, \App\AI\Services\AiInsightEngine $insightEngine): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Only administrators can access executive summaries.',
            ], 403);
        }

        $summary = $insightEngine->generateExecutiveSummary($user);

        return response()->json([
            'status' => 'success',
            'data' => $summary,
        ]);
    }

    /**
     * Acknowledge or dismiss an AI alert
     * POST /api/ai/insights/acknowledge
     */
    public function acknowledgeInsight(Request $request, \App\AI\Services\AiInsightEngine $insightEngine): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'alert_id' => 'required|string',
            'action' => 'nullable|string|in:ACKNOWLEDGED,DISMISSED',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $result = $insightEngine->acknowledgeAlert(
            $user, 
            $request->input('alert_id'), 
            $request->input('action', 'ACKNOWLEDGED')
        );

        return response()->json([
            'status' => 'success',
            'data' => $result,
        ]);
    }

    /**
     * Introspect registered AI models from centralized Model Registry
     * GET /api/ai/models
     */
    public function models(\App\AI\Services\AiModelRegistry $modelRegistry): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'active_local' => $modelRegistry->getActiveLocalModel(),
                'active_cloud' => $modelRegistry->getActiveCloudModel(),
                'total_models' => count($modelRegistry->getAllModels()),
                'models' => $modelRegistry->getAllModels(),
            ],
        ]);
    }
}

