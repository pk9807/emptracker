<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;

class GetShopVisitsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_shop_visits';
    }

    public function getDescription(): string
    {
        return 'Retrieve visit history for a specific shop (Employees see their own visits; Admins see all field agent visits).';
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
                'limit' => [
                    'type' => 'integer',
                    'description' => 'Maximum visits to retrieve (default 10, max 50)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'shop_id' => ['type' => 'integer'],
                'shop_name' => ['type' => 'string'],
                'total_visits' => ['type' => 'integer'],
                'visits' => ['type' => 'array'],
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
        $start = microtime(true);
        $this->permissionService->authorizeTool($user, $this);

        $shopId = (int)($parameters['shop_id'] ?? 0);
        $shop = Shop::find($shopId);

        if (!$shop) {
            return AiToolResult::failure($this->getName(), "Shop not found with ID {$shopId}");
        }

        $query = Visit::with('user:id,name,employee_code')->where('shop_id', $shopId);

        // If user is employee, only show their own visits to this shop
        if (UserRole::fromString($user->role) === UserRole::EMPLOYEE) {
            $query->where('user_id', $user->id);
        }

        $limit = min((int)($parameters['limit'] ?? 10), 50);
        $visits = $query->orderBy('check_in_time', 'desc')->limit($limit)->get();

        $formatted = $visits->map(function ($v) {
            return [
                'id' => $v->id,
                'employee_name' => $v->user ? $v->user->name : 'Unknown Employee',
                'check_in_time' => (string)$v->check_in_time,
                'check_out_time' => (string)$v->check_out_time,
                'is_verified_geofence' => (bool)$v->is_verified_geofence,
                'order_amount' => (float)$v->order_amount,
                'notes' => $v->notes,
            ];
        });

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'shop_id' => $shop->id,
            'shop_name' => $shop->name,
            'total_visits' => $formatted->count(),
            'visits' => $formatted->toArray(),
        ], $executionTime);
    }
}
