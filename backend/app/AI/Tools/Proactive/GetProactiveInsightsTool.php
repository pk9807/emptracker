<?php

namespace App\AI\Tools\Proactive;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiInsightEngine;
use App\AI\Services\AiPermissionService;
use App\Models\User;

class GetProactiveInsightsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;
    protected AiInsightEngine $insightEngine;

    public function __construct(AiPermissionService $permissionService, ?AiInsightEngine $insightEngine = null)
    {
        $this->permissionService = $permissionService;
        $this->insightEngine = $insightEngine ?? new AiInsightEngine();
    }

    public function getName(): string
    {
        return 'get_proactive_insights';
    }

    public function getDescription(): string
    {
        return 'Fetches active, prioritized proactive operational alerts and risk signals.';
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::EMPLOYEE; // Accessible to all authenticated users; filtered by role inside
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::INTERNAL;
    }

    public function isWriteAction(): bool
    {
        return false;
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'severity_filter' => [
                    'type' => 'string',
                    'enum' => ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'],
                    'description' => 'Optional filter by severity level',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'user' => ['type' => 'string'],
                'total_alerts' => ['type' => 'integer'],
                'insights' => ['type' => 'array'],
                'map_action' => ['type' => 'object'],
            ],
        ];
    }

    public function execute(User $user, array $parameters = []): AiToolResult
    {
        $this->permissionService->authorizeTool($user, $this);

        $insights = $this->insightEngine->getActiveInsights($user);
        $filter = $parameters['severity_filter'] ?? 'ALL';

        if ($filter !== 'ALL') {
            $insights = array_values(array_filter($insights, fn($i) => $i['severity'] === $filter));
        }

        return AiToolResult::success($this->getName(), [
            'user' => $user->name,
            'total_alerts' => count($insights),
            'insights' => $insights,
            'entities' => array_map(fn($i) => [
                'type' => $i['entity_type'],
                'id' => $i['entity_id'],
                'name' => $i['entity_name'],
            ], array_slice($insights, 0, 5)),
            'map_action' => [
                'type' => 'show_alerts',
                'count' => count($insights),
            ],
        ]);
    }
}
