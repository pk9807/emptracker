<?php

namespace App\AI\Tools\ReadOnly;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Services\AiPermissionService;
use App\Models\User;

class SearchEmployeesTool implements AiToolInterface
{
    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    public function getName(): string
    {
        return 'search_employees';
    }

    public function getDescription(): string
    {
        return 'Search employee directory by name, employee code, department, designation, or active status (Admin only).';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'query' => [
                    'type' => 'string',
                    'description' => 'Keyword to match against name, email, employee code, or department',
                ],
                'is_active' => [
                    'type' => 'boolean',
                    'description' => 'Filter by active (true) or inactive (false) status',
                ],
                'department' => [
                    'type' => 'string',
                    'description' => 'Filter by specific department',
                ],
                'limit' => [
                    'type' => 'integer',
                    'description' => 'Maximum number of records to return (default 10, max 50)',
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
                'employees' => [
                    'type' => 'array',
                    'items' => [
                        'type' => 'object',
                        'properties' => [
                            'id' => ['type' => 'integer'],
                            'name' => ['type' => 'string'],
                            'email' => ['type' => 'string'],
                            'employee_code' => ['type' => 'string'],
                            'department' => ['type' => 'string'],
                            'designation' => ['type' => 'string'],
                            'is_active' => ['type' => 'boolean'],
                        ],
                    ],
                ],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::ADMIN;
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

        $query = User::query()->where('role', 'employee');

        if (!empty($parameters['query'])) {
            $keyword = trim($parameters['query']);
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('email', 'like', "%{$keyword}%")
                  ->orWhere('employee_code', 'like', "%{$keyword}%")
                  ->orWhere('department', 'like', "%{$keyword}%")
                  ->orWhere('designation', 'like', "%{$keyword}%");
            });
        }

        if (isset($parameters['is_active'])) {
            $query->where('is_active', (bool)$parameters['is_active']);
        }

        if (!empty($parameters['department'])) {
            $query->where('department', 'like', '%' . trim($parameters['department']) . '%');
        }

        $limit = min((int)($parameters['limit'] ?? 10), 50);
        $employees = $query->limit($limit)->get([
            'id', 'name', 'email', 'phone', 'employee_code', 'department', 'designation', 'is_active',
        ]);

        $executionTime = (microtime(true) - $start) * 1000;

        return AiToolResult::success($this->getName(), [
            'count' => $employees->count(),
            'employees' => $employees->toArray(),
        ], $executionTime);
    }
}
