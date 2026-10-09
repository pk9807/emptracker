<?php

namespace App\AI\Tools\Proactive;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiInsightEngine;
use App\AI\Services\AiPermissionService;
use App\Models\User;

class GetDailyOperationalSummaryTool implements AiToolInterface
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
        return 'get_daily_operational_summary';
    }

    public function getDescription(): string
    {
        return 'Generates high-level executive operational intelligence and risk summary.';
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::ADMIN;
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::SENSITIVE;
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
                'date' => [
                    'type' => 'string',
                    'description' => 'Optional date for operational summary (YYYY-MM-DD)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'status' => ['type' => 'string'],
                'total_alerts' => ['type' => 'integer'],
                'counts' => ['type' => 'object'],
                'executive_summary' => ['type' => 'string'],
                'top_insights' => ['type' => 'array'],
            ],
        ];
    }

    public function execute(User $user, array $parameters = []): AiToolResult
    {
        $this->permissionService->authorizeTool($user, $this);

        $summary = $this->insightEngine->generateExecutiveSummary($user);

        return AiToolResult::success($this->getName(), $summary);
    }
}
