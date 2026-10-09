<?php

namespace App\AI\Contracts;

use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\Models\User;

interface AiToolInterface
{
    /**
     * Unique machine-readable name of the tool (e.g., 'get_employee_location')
     */
    public function getName(): string;

    /**
     * Human and model readable description of what the tool accomplishes
     */
    public function getDescription(): string;

    /**
     * JSON Schema array for input parameter validation
     */
    public function getInputSchema(): array;

    /**
     * JSON Schema array for output representation
     */
    public function getOutputSchema(): array;

    /**
     * Required minimum role to execute this tool
     */
    public function getRequiredRole(): UserRole;

    /**
     * Sensitivity tier for privacy guardrails
     */
    public function getDataSensitivity(): DataSensitivity;

    /**
     * Whether this tool modifies data (write action requiring 2-step confirmation)
     */
    public function isWriteAction(): bool;

    /**
     * Execute the tool with validated parameters under the authenticated user's context
     *
     * @param User $user Authenticated actor
     * @param array $parameters Validated tool inputs
     * @return AiToolResult
     */
    public function execute(User $user, array $parameters): AiToolResult;
}
