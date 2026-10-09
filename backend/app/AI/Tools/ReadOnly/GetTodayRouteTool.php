<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\EmployeeShop;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;

class GetTodayRouteTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_today_route';
    }

    public function getDescription(): string
    {
        return 'Retrieve assigned shops, completed vs pending visits, and daily route agenda for an employee.';
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
                    'description' => 'Target date (YYYY-MM-DD), default is today',
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
                'date' => ['type' => 'string'],
                'total_assigned_shops' => ['type' => 'integer'],
                'completed_visits_count' => ['type' => 'integer'],
                'pending_visits_count' => ['type' => 'integer'],
                'route' => ['type' => 'array'],
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

        $date = !empty($parameters['date']) ? $parameters['date'] : Carbon::today()->toDateString();

        // 1. Fetch assigned shops for employee
        $assignedShops = EmployeeShop::with('shop')
            ->where('user_id', $targetId)
            ->get();

        // If no explicit assignments in pivot, fall back to active shops
        if ($assignedShops->isEmpty()) {
            $allActiveShops = Shop::where('status', 'ACTIVE')->limit(5)->get();
            $assignedList = $allActiveShops;
        } else {
            $assignedList = $assignedShops->map(fn($as) => $as->shop)->filter();
        }

        // 2. Fetch visits completed on that date
        $visitsToday = Visit::where('user_id', $targetId)
            ->whereDate('check_in_time', $date)
            ->get()
            ->keyBy('shop_id');

        $routeItems = [];
        $completedCount = 0;

        foreach ($assignedList as $shop) {
            $visited = $visitsToday->has($shop->id);
            if ($visited) {
                $completedCount++;
            }

            $routeItems[] = [
                'shop_id' => $shop->id,
                'shop_name' => $shop->name,
                'address' => $shop->address,
                'category' => $shop->category,
                'latitude' => (float)$shop->latitude,
                'longitude' => (float)$shop->longitude,
                'is_visited' => $visited,
                'visit_status' => $visited ? 'COMPLETED' : 'PENDING',
                'order_amount' => $visited ? (float)$visitsToday->get($shop->id)->order_amount : 0.0,
            ];
        }

        $totalAssigned = count($routeItems);
        $pendingCount = $totalAssigned - $completedCount;

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'employee_id' => $targetUser->id,
            'employee_name' => $targetUser->name,
            'date' => $date,
            'total_assigned_shops' => $totalAssigned,
            'completed_visits_count' => $completedCount,
            'pending_visits_count' => $pendingCount,
            'route' => $routeItems,
        ], $executionTime);
    }
}
