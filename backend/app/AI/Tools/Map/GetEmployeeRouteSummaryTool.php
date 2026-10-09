<?php

namespace App\AI\Tools\Map;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\AI\Services\MapIntelligenceService;
use App\Models\User;

class GetEmployeeRouteSummaryTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;
    protected MapIntelligenceService $mapService;

    public function __construct(AiPermissionService $permissionService, MapIntelligenceService $mapService)
    {
        $this->permissionService = $permissionService;
        $this->mapService = $mapService;
    }

    public function getName(): string
    {
        return 'get_employee_route_summary';
    }

    public function getDescription(): string
    {
        return 'Analyzes full GPS trajectory, total kilometers, idle duration, and shop checkpoints for an employee.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target employee ID',
                ],
                'date' => [
                    'type' => 'string',
                    'description' => 'Target date in YYYY-MM-DD format (defaults to today)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'found' => ['type' => 'boolean'],
                'employee_name' => ['type' => 'string'],
                'total_distance_km' => ['type' => 'number'],
                'idle_duration_minutes' => ['type' => 'integer'],
                'total_visits_completed' => ['type' => 'integer'],
                'visited_shops' => ['type' => 'array'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::EMPLOYEE;
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::SENSITIVE;
    }

    public function isWriteAction(): bool
    {
        return false;
    }

    public function execute(User $user, array $parameters): AiToolResult
    {
        $this->permissionService->enforceEmployeeIsolation($user, $parameters);

        $empId = (int)($parameters['employee_id'] ?? $user->id);
        $date = $parameters['date'] ?? null;

        $summary = $this->mapService->getRouteSummary($empId, $date);

        return AiToolResult::success($this->getName(), array_merge($summary, [
            'map_action' => [
                'type' => 'draw_route_playback',
                'employee_id' => $empId,
                'date' => $summary['date'] ?? null,
            ],
        ]));
    }
}
