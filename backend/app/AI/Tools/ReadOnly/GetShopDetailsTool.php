<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\Shop;
use App\Models\User;

class GetShopDetailsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_shop_details';
    }

    public function getDescription(): string
    {
        return 'Retrieve detailed information, geofence radius, owner contact, and coordinates of a specific shop.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'required' => ['shop_id'],
            'properties' => [
                'shop_id' => [
                    'type' => 'integer',
                    'description' => 'Target shop ID',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'id' => ['type' => 'integer'],
                'name' => ['type' => 'string'],
                'owner_name' => ['type' => 'string'],
                'phone' => ['type' => 'string'],
                'address' => ['type' => 'string'],
                'category' => ['type' => 'string'],
                'latitude' => ['type' => 'number'],
                'longitude' => ['type' => 'number'],
                'geofence_radius_meters' => ['type' => 'integer'],
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

        $shopId = (int)($parameters['shop_id'] ?? 0);
        $shop = Shop::find($shopId);

        if (!$shop) {
            return AiToolResult::failure($this->getName(), "Shop not found with ID {$shopId}");
        }

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'id' => $shop->id,
            'name' => $shop->name,
            'owner_name' => $shop->owner_name,
            'phone' => $shop->phone,
            'address' => $shop->address,
            'category' => $shop->category,
            'latitude' => (float)$shop->latitude,
            'longitude' => (float)$shop->longitude,
            'geofence_radius_meters' => (int)$shop->geofence_radius_meters,
            'status' => $shop->status,
        ], $executionTime);
    }
}
