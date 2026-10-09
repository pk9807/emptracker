<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\Shop;
use App\Models\User;

class SearchShopsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'search_shops';
    }

    public function getDescription(): string
    {
        return 'Search registered shops and outlets by name, owner, category, or address keyword.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'query' => [
                    'type' => 'string',
                    'description' => 'Keyword to match against shop name, owner name, category, or address',
                ],
                'category' => [
                    'type' => 'string',
                    'description' => 'Filter by shop category (e.g. RETAIL, WHOLESALE, PHARMACY)',
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

        $query = Shop::query()->where('status', 'ACTIVE');

        if (!empty($parameters['query'])) {
            $keyword = trim($parameters['query']);
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('owner_name', 'like', "%{$keyword}%")
                  ->orWhere('address', 'like', "%{$keyword}%")
                  ->orWhere('category', 'like', "%{$keyword}%");
            });
        }

        if (!empty($parameters['category'])) {
            $query->where('category', strtoupper(trim($parameters['category'])));
        }

        $limit = min((int)($parameters['limit'] ?? 10), 50);
        $shops = $query->limit($limit)->get([
            'id', 'name', 'owner_name', 'phone', 'address', 'category', 'latitude', 'longitude', 'geofence_radius_meters',
        ]);

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'count' => $shops->count(),
            'shops' => $shops->toArray(),
        ], $executionTime);
    }
}
