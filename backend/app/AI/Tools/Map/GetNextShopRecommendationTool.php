<?php

namespace App\AI\Tools\Map;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\AI\Services\MapIntelligenceService;
use App\Models\User;

class GetNextShopRecommendationTool implements AiToolInterface
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
        return 'get_next_shop_recommendation';
    }

    public function getDescription(): string
    {
        return 'Recommends the best next assigned shop to visit based on GPS proximity and visit urgency.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target employee ID (defaults to authenticated employee)',
                ],
                'latitude' => [
                    'type' => 'number',
                    'description' => 'Current live latitude',
                ],
                'longitude' => [
                    'type' => 'number',
                    'description' => 'Current live longitude',
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
                'all_completed' => ['type' => 'boolean'],
                'recommended_shop' => ['type' => 'object'],
                'pending_candidates' => ['type' => 'array'],
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
        $this->permissionService->enforceEmployeeIsolation($user, $parameters);

        $empId = (int)($parameters['employee_id'] ?? $user->id);
        $lat = isset($parameters['latitude']) ? (float)$parameters['latitude'] : null;
        $lng = isset($parameters['longitude']) ? (float)$parameters['longitude'] : null;

        $result = $this->mapService->recommendNextShop($empId, $lat, $lng);

        $entities = [];
        if (!empty($result['recommended_shop'])) {
            $rec = $result['recommended_shop'];
            $entities[] = [
                'type' => 'shop',
                'id' => $rec['shop_id'],
                'name' => $rec['name'],
                'latitude' => $rec['latitude'],
                'longitude' => $rec['longitude'],
                'action' => 'show_on_map',
            ];
        }

        return AiToolResult::success($this->getName(), array_merge($result, [
            'entities' => $entities,
            'map_action' => [
                'type' => 'focus_recommended_shop',
                'shop_id' => $result['recommended_shop']['shop_id'] ?? null,
            ],
        ]));
    }
}
