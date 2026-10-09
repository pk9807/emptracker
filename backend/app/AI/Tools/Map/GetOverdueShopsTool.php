<?php

namespace App\AI\Tools\Map;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\AI\Services\MapIntelligenceService;
use App\Models\User;

class GetOverdueShopsTool implements AiToolInterface
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
        return 'get_overdue_shops';
    }

    public function getDescription(): string
    {
        return 'Finds retail shops that have not been visited for a specified number of days (e.g. 7 days).';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'days' => [
                    'type' => 'integer',
                    'description' => 'Threshold in days without visits (default 7)',
                ],
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Optional employee ID filter for assigned shops',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'threshold_days' => ['type' => 'integer'],
                'total_overdue' => ['type' => 'integer'],
                'shops' => ['type' => 'array'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::EMPLOYEE;
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::INTERNAL;
    }

    public function isWriteAction(): bool
    {
        return false;
    }

    public function execute(User $user, array $parameters): AiToolResult
    {
        $days = (int)($parameters['days'] ?? 7);
        $empId = isset($parameters['employee_id']) ? (int)$parameters['employee_id'] : null;

        if ($user->role === 'employee') {
            $empId = $user->id; // Enforce self isolation
        }

        $result = $this->mapService->getOverdueShops($days, $empId);

        // Attach structured entities for Flutter map interaction
        $entities = array_map(fn($s) => [
            'type' => 'shop',
            'id' => $s['shop_id'],
            'name' => $s['name'],
            'latitude' => $s['latitude'],
            'longitude' => $s['longitude'],
            'action' => 'show_on_map',
        ], $result['shops']);

        return AiToolResult::success($this->getName(), [
            'threshold_days' => $result['threshold_days'],
            'total_overdue' => $result['total_overdue'],
            'shops' => $result['shops'],
            'entities' => $entities,
            'map_action' => [
                'type' => 'filter_overdue_shops',
                'count' => $result['total_overdue'],
            ],
        ]);
    }
}
