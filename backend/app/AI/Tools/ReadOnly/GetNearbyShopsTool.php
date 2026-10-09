<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\Shop;
use App\Models\User;

class GetNearbyShopsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_nearby_shops';
    }

    public function getDescription(): string
    {
        return 'Find registered shops closest to given GPS coordinates within a specified radius (in kilometers) sorted by distance.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'required' => ['latitude', 'longitude'],
            'properties' => [
                'latitude' => [
                    'type' => 'number',
                    'description' => 'Target latitude (e.g. 26.4499 for Kanpur)',
                ],
                'longitude' => [
                    'type' => 'number',
                    'description' => 'Target longitude (e.g. 80.3319 for Kanpur)',
                ],
                'radius_km' => [
                    'type' => 'number',
                    'description' => 'Search radius in kilometers (default 15 km, max 100 km)',
                ],
                'limit' => [
                    'type' => 'integer',
                    'description' => 'Maximum shops to return (default 10, max 50)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'origin' => ['type' => 'object'],
                'radius_km' => ['type' => 'number'],
                'count' => ['type' => 'integer'],
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
        $start = microtime(true);
        $this->permissionService->authorizeTool($user, $this);

        $lat = (float)($parameters['latitude'] ?? 26.4499);
        $lng = (float)($parameters['longitude'] ?? 80.3319);
        $radiusKm = min((float)($parameters['radius_km'] ?? 15.0), 100.0);
        $limit = min((int)($parameters['limit'] ?? 10), 50);

        // Fetch all active shops with coordinates
        $shops = Shop::where('status', 'ACTIVE')->get();
        $results = [];

        foreach ($shops as $shop) {
            $dist = $this->calculateHaversineDistance($lat, $lng, (float)$shop->latitude, (float)$shop->longitude);
            if ($dist <= $radiusKm) {
                $results[] = [
                    'id' => $shop->id,
                    'name' => $shop->name,
                    'owner_name' => $shop->owner_name,
                    'phone' => $shop->phone,
                    'address' => $shop->address,
                    'category' => $shop->category,
                    'latitude' => (float)$shop->latitude,
                    'longitude' => (float)$shop->longitude,
                    'distance_km' => round($dist, 2),
                ];
            }
        }

        // Sort by nearest distance
        usort($results, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);
        $sliced = array_slice($results, 0, $limit);

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'origin' => ['latitude' => $lat, 'longitude' => $lng],
            'radius_km' => $radiusKm,
            'count' => count($sliced),
            'shops' => $sliced,
        ], $executionTime);
    }

    private function calculateHaversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadiusKm * $c;
    }
}
