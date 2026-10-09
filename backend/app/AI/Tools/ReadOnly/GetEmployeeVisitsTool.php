<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;

class GetEmployeeVisitsTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_employee_visits';
    }

    public function getDescription(): string
    {
        return 'Retrieve shop visits completed by an employee, including geofence verification and order amounts.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target employee ID (Admins can specify any ID, Employees restricted to self)',
                ],
                'date' => [
                    'type' => 'string',
                    'description' => 'Specific visit date (YYYY-MM-DD), default is today',
                ],
                'limit' => [
                    'type' => 'integer',
                    'description' => 'Maximum records to fetch (default 20, max 50)',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => ['type' => 'integer'],
                'employee_name' => ['type' => 'string'],
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
        $this->permissionService->enforceEmployeeIsolation($user, $parameters);

        $targetId = (int)($parameters['employee_id'] ?? $user->id);
        $targetUser = User::find($targetId);

        if (!$targetUser) {
            return AiToolResult::failure($this->getName(), "Employee not found with ID {$targetId}");
        }

        $query = Visit::with('shop:id,name,address,category')->where('user_id', $targetId);

        if (!empty($parameters['date'])) {
            $query->whereDate('check_in_time', $parameters['date']);
        }

        $limit = min((int)($parameters['limit'] ?? 20), 50);
        $visits = $query->orderBy('check_in_time', 'desc')->limit($limit)->get();

        $formatted = $visits->map(function ($v) {
            return [
                'id' => $v->id,
                'shop_name' => $v->shop ? $v->shop->name : 'Unknown Shop',
                'shop_address' => $v->shop ? $v->shop->address : null,
                'check_in_time' => (string)$v->check_in_time,
                'check_out_time' => (string)$v->check_out_time,
                'is_verified_geofence' => (bool)$v->is_verified_geofence,
                'order_amount' => (float)$v->order_amount,
                'status' => $v->status,
                'notes' => $v->notes,
            ];
        });

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'employee_id' => $targetUser->id,
            'employee_name' => $targetUser->name,
            'total_visits' => $formatted->count(),
            'visits' => $formatted->toArray(),
        ], $executionTime);
    }
}
