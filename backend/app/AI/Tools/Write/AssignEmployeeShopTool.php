<?php

namespace App\AI\Tools\Write;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiValidationException;
use App\Models\EmployeeShop;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AssignEmployeeShopTool implements AiToolInterface
{
    public function getName(): string
    {
        return 'assign_employee_shop';
    }

    public function getDescription(): string
    {
        return 'Assigns a retail store/shop to a field employee for scheduled daily visits. Requires admin confirmation.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'required' => ['employee_id', 'shop_id'],
            'properties' => [
                'employee_id' => [
                    'type' => 'integer',
                    'description' => 'Target employee user ID',
                ],
                'shop_id' => [
                    'type' => 'integer',
                    'description' => 'Target shop database ID',
                ],
            ],
        ];
    }

    public function getOutputSchema(): array
    {
        return [
            'type' => 'object',
            'properties' => [
                'success' => ['type' => 'boolean'],
                'message' => ['type' => 'string'],
                'assignment_id' => ['type' => 'integer'],
                'employee_name' => ['type' => 'string'],
                'shop_name' => ['type' => 'string'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::ADMIN;
    }

    public function getDataSensitivity(): DataSensitivity
    {
        return DataSensitivity::INTERNAL;
    }

    public function isWriteAction(): bool
    {
        return true;
    }

    public function execute(User $user, array $parameters): AiToolResult
    {
        $employeeId = $parameters['employee_id'] ?? null;
        $shopId = $parameters['shop_id'] ?? null;

        if (!$employeeId || !$shopId) {
            throw new AiValidationException("Employee ID and Shop ID are required for assignment.");
        }

        $employee = User::where('id', $employeeId)->where('role', 'employee')->first();
        if (!$employee) {
            throw new AiValidationException("Employee with ID {$employeeId} was not found or is not an active field executive.");
        }

        $shop = Shop::find($shopId);
        if (!$shop) {
            throw new AiValidationException("Shop with ID {$shopId} was not found.");
        }

        // Check if already assigned
        $existing = EmployeeShop::where('user_id', $employee->id)
            ->where('shop_id', $shop->id)
            ->first();

        if ($existing) {
            return AiToolResult::success($this->getName(), [
                'success' => true,
                'message' => "Shop '{$shop->name}' is already assigned to {$employee->name}.",
                'assignment_id' => $existing->id,
                'employee_name' => $employee->name,
                'shop_name' => $shop->name,
                'already_existed' => true,
            ]);
        }

        // Execute assignment inside DB transaction
        $assignment = DB::transaction(function () use ($employee, $shop) {
            return EmployeeShop::create([
                'user_id' => $employee->id,
                'shop_id' => $shop->id,
            ]);
        });

        return AiToolResult::success($this->getName(), [
            'success' => true,
            'message' => "Successfully assigned shop '{$shop->name}' to employee {$employee->name} (Code: {$employee->employee_code}).",
            'assignment_id' => $assignment->id,
            'employee_name' => $employee->name,
            'shop_name' => $shop->name,
            'already_existed' => false,
        ]);
    }
}
