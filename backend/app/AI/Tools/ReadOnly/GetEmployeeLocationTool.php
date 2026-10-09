<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\LiveLocation;
use App\Models\User;

class GetEmployeeLocationTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_employee_location';
    }

    public function getDescription(): string
    {
        return 'Retrieve latest verified GPS telemetry, battery level, online status, and activity state of an employee.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target employee ID (Admin can specify any ID, Employees restricted to self)',
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
                'latitude' => ['type' => 'number'],
                'longitude' => ['type' => 'number'],
                'accuracy' => ['type' => 'number'],
                'speed' => ['type' => 'number'],
                'battery_level' => ['type' => 'integer'],
                'is_online' => ['type' => 'boolean'],
                'activity_type' => ['type' => 'string'],
                'last_ping_at' => ['type' => 'string'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::EMPLOYEE;
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::HIGHLY_SENSITIVE;
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

        $live = LiveLocation::where('user_id', $targetId)->first();

        if (!$live) {
            return AiToolResult::success($this->getName(), [
                'employee_id' => $targetUser->id,
                'employee_name' => $targetUser->name,
                'status' => 'offline',
                'message' => 'No GPS telemetry recorded yet for this employee.',
            ], (microtime(true) - $start) * 1000);
        }

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'employee_id' => $targetUser->id,
            'employee_name' => $targetUser->name,
            'latitude' => (float)$live->latitude,
            'longitude' => (float)$live->longitude,
            'accuracy' => (float)$live->accuracy,
            'speed' => (float)$live->speed,
            'battery_level' => (int)$live->battery_level,
            'is_online' => (bool)$live->is_online,
            'activity_type' => $live->activity_type,
            'last_ping_at' => (string)$live->last_ping_at,
        ], $executionTime);
    }
}
