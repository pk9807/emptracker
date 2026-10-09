<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\User;

class GetEmployeeProfileTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'get_employee_profile';
    }

    public function getDescription(): string
    {
        return 'Get profile, designation, department, and account status of an employee.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target user ID (Admins can specify any ID, Employees restricted to self)',
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
                'email' => ['type' => 'string'],
                'phone' => ['type' => 'string'],
                'employee_code' => ['type' => 'string'],
                'department' => ['type' => 'string'],
                'designation' => ['type' => 'string'],
                'is_active' => ['type' => 'boolean'],
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

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'id' => $targetUser->id,
            'name' => $targetUser->name,
            'email' => $targetUser->email,
            'phone' => $targetUser->phone,
            'employee_code' => $targetUser->employee_code,
            'department' => $targetUser->department,
            'designation' => $targetUser->designation,
            'is_active' => (bool)$targetUser->is_active,
        ], $executionTime);
    }
}
