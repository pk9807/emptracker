<?php

namespace App\AI\Services;

use App\AI\Contracts\AiToolInterface;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\Models\User;

class AiPermissionService
{
    /**
     * Verify if the user has permission to execute the specified tool
     */
    public function authorizeTool(User $user, AiToolInterface $tool): void
    {
        $userRole = UserRole::fromString($user->role);
        $requiredRole = $tool->getRequiredRole();

        // Admin can execute all tools
        if ($userRole === UserRole::ADMIN) {
            return;
        }

        // Employee can only execute tools requiring EMPLOYEE role
        if ($requiredRole === UserRole::ADMIN && $userRole !== UserRole::ADMIN) {
            throw new AiPermissionDeniedException(
                "Access denied: Tool '{$tool->getName()}' requires administrator privileges."
            );
        }
    }

    /**
     * Enforce employee data isolation: an employee can only query their own user_id / employee_id
     */
    public function enforceEmployeeIsolation(User $user, array &$parameters): void
    {
        $userRole = UserRole::fromString($user->role);

        if ($userRole === UserRole::ADMIN) {
            return; // Admin can inspect any target user
        }

        // For non-admin employees, target user_id MUST match their own ID
        if (isset($parameters['user_id']) && (int)$parameters['user_id'] !== (int)$user->id) {
            throw new AiPermissionDeniedException(
                "Access denied: You cannot view or query data belonging to another employee."
            );
        }

        if (isset($parameters['employee_id']) && (int)$parameters['employee_id'] !== (int)$user->id) {
            throw new AiPermissionDeniedException(
                "Access denied: You cannot view or query data belonging to another employee."
            );
        }

        // Auto-bind user_id to the authenticated employee's ID if missing
        $parameters['user_id'] = $user->id;
        $parameters['employee_id'] = $user->id;
    }
}
