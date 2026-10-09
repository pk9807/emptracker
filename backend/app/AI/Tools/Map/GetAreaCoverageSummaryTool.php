<?php

namespace App\AI\Tools\Map;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\AI\Services\MapIntelligenceService;
use App\Models\User;

class GetAreaCoverageSummaryTool implements AiToolInterface
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
        return 'get_area_coverage_summary';
    }

    public function getDescription(): string
    {
        return 'Calculates aggregate shop visit coverage percentage and active field checkpoints in a geographic region.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'latitude' => [
                    'type' => 'number',
                    'description' => 'Center latitude (defaults to Kanpur 26.4499)',
                ],
                'longitude' => [
                    'type' => 'number',
                    'description' => 'Center longitude (defaults to Kanpur 80.3319)',
                ],
                'radius_km' => [
                    'type' => 'number',
                    'description' => 'Radius in kilometers (default 15.0)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'total_shops_in_area' => ['type' => 'integer'],
                'covered_shops_count' => ['type' => 'integer'],
                'pending_shops_count' => ['type' => 'integer'],
                'coverage_percentage' => ['type' => 'number'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::ADMIN;
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
        $lat = (float)($parameters['latitude'] ?? 26.4499);
        $lng = (float)($parameters['longitude'] ?? 80.3319);
        $radius = (float)($parameters['radius_km'] ?? 15.0);

        $summary = $this->mapService->getAreaCoverageSummary($lat, $lng, $radius);

        return AiToolResult::success($this->getName(), array_merge($summary, [
            'map_action' => [
                'type' => 'highlight_coverage_polygon',
                'center' => ['latitude' => $lat, 'longitude' => $lng],
                'radius_km' => $radius,
            ],
        ]));
    }
}
