<?php

namespace App\AI\Tools\Write;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiValidationException;
use App\Models\Shop;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AddShopUrgentNoteTool implements AiToolInterface
{
    public function getName(): string
    {
        return 'add_shop_urgent_note';
    }

    public function getDescription(): string
    {
        return 'Appends an urgent operational note or special instructions to a shop record. Requires user confirmation.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'required' => ['shop_id', 'note'],
            'properties' => [
                'shop_id' => [
                    'type' => 'integer',
                    'description' => 'Database ID of the shop',
                ],
                'note' => [
                    'type' => 'string',
                    'description' => 'Urgent note / special delivery / payment collection instructions',
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
                'shop_id' => ['type' => 'integer'],
                'shop_name' => ['type' => 'string'],
                'updated_note' => ['type' => 'string'],
            ],
        ];
    }

    public function getRequiredRole(): UserRole
    {
        return UserRole::EMPLOYEE;
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
        $shopId = $parameters['shop_id'] ?? null;
        $note = trim($parameters['note'] ?? '');

        if (!$shopId || empty($note)) {
            throw new AiValidationException("Shop ID and note content are required.");
        }

        $shop = Shop::find($shopId);
        if (!$shop) {
            throw new AiValidationException("Shop with ID {$shopId} was not found.");
        }

        $timestamp = Carbon::now()->format('m-d H:i');
        $noteEntry = "[URGENT {$timestamp} - {$user->name}]: {$note}";

        // Preserve base address and append fresh urgent note
        $updated = DB::transaction(function () use ($shop, $noteEntry) {
            $existingAddress = $shop->address ?? '';
            if (str_contains($existingAddress, ' | [URGENT')) {
                $existingAddress = explode(' | [URGENT', $existingAddress)[0];
            }
            $newAddress = substr($existingAddress . " | " . $noteEntry, 0, 250);
            $shop->update([
                'address' => $newAddress,
            ]);
            return $shop;
        });

        return AiToolResult::success($this->getName(), [
            'success' => true,
            'message' => "Urgent note successfully recorded for shop '{$shop->name}'.",
            'shop_id' => $shop->id,
            'shop_name' => $shop->name,
            'recorded_by' => $user->name,
            'note' => $note,
        ]);
    }
}
