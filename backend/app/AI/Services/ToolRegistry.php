<?php

namespace App\AI\Services;

use App\AI\Contracts\AiToolInterface;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiValidationException;
use App\Models\User;

class ToolRegistry
{
    /**
     * @var array<string, AiToolInterface>
     */
    protected array $tools = [];

    protected AiPermissionService $permissionService;

    public function __construct(AiPermissionService $permissionService)
    {
        $this->permissionService = $permissionService;
    }

    /**
     * Register a tool into the registry
     */
    public function registerTool(AiToolInterface $tool): self
    {
        $this->tools[$tool->getName()] = $tool;
        return $this;
    }

    /**
     * Get a specific tool by name
     */
    public function getTool(string $name): ?AiToolInterface
    {
        return $this->tools[$name] ?? null;
    }

    /**
     * Check if a tool exists
     */
    public function hasTool(string $name): bool
    {
        return isset($this->tools[$name]);
    }

    /**
     * Return all tools registered in the system
     *
     * @return array<string, AiToolInterface>
     */
    public function getAllTools(): array
    {
        return $this->tools;
    }

    /**
     * Get tools filtered by user's role permission
     *
     * @param User $user
     * @return array<string, AiToolInterface>
     */
    public function getToolsForUser(User $user): array
    {
        $role = UserRole::fromString($user->role);
        $accessible = [];

        foreach ($this->tools as $name => $tool) {
            if ($role === UserRole::ADMIN || $tool->getRequiredRole() === UserRole::EMPLOYEE) {
                $accessible[$name] = $tool;
            }
        }

        return $accessible;
    }

    /**
     * Generate tool schemas for AI model prompt / function calling
     */
    public function getToolSchemasForUser(User $user): array
    {
        $tools = $this->getToolsForUser($user);
        $schemas = [];

        foreach ($tools as $tool) {
            $schemas[] = [
                'name' => $tool->getName(),
                'description' => $tool->getDescription(),
                'parameters' => $tool->getInputSchema(),
                'required_role' => $tool->getRequiredRole()->value,
                'data_sensitivity' => $tool->getDataSensitivity()->value,
                'is_write_action' => $tool->isWriteAction(),
            ];
        }

        return $schemas;
    }
}
