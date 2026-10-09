<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\Attendance;
use App\Models\User;
use Carbon\Carbon;

class GetEmployeeAttendanceTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_employee_attendance';
    }

    public function getDescription(): string
    {
        return 'Retrieve attendance records, punch-in/out timestamps, daily travel distance, and duty status for an employee.';
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
                    'description' => 'Specific date (YYYY-MM-DD), default is today',
                ],
                'days' => [
                    'type' => 'integer',
                    'description' => 'Number of days history to retrieve (default 7, max 30)',
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
                'total_records' => ['type' => 'integer'],
                'records' => ['type' => 'array'],
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

        $query = Attendance::where('user_id', $targetId);

        if (!empty($parameters['date'])) {
            $query->whereDate('date', $parameters['date']);
        } else {
            $days = min((int)($parameters['days'] ?? 7), 30);
            $query->whereDate('date', '>=', Carbon::today()->subDays($days));
        }

        $records = $query->orderBy('date', 'desc')->get([
            'id', 'date', 'check_in_time', 'check_out_time', 'total_distance_km', 'status', 'battery_level',
        ]);

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'employee_id' => $targetUser->id,
            'employee_name' => $targetUser->name,
            'total_records' => $records->count(),
            'records' => $records->toArray(),
        ], $executionTime);
    }
}
