<?php

namespace App\AI\Tools\Write;

use App\AI\Contracts\AiToolInterface;
use App\AI\DTOs\AiToolResult;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Exceptions\AiValidationException;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class RecordVisitRemarkTool implements AiToolInterface
{
    public function getName(): string
    {
        return 'record_visit_remark';
    }

    public function getDescription(): string
    {
        return 'Records or updates remark/notes on a shop visit. Requires user confirmation.';
    }

    public function getInputSchema(): array
    {
        return [
            'type' => 'object',
            'required' => ['shop_id', 'remark'],
            'properties' => [
                'shop_id' => [
                    'type' => 'integer',
                    'description' => 'Target shop database ID',
                ],
                'remark' => [
                    'type' => 'string',
                    'description' => 'Visit remark, outcome, or customer feedback note',
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
                'visit_id' => ['type' => 'integer'],
                'shop_name' => ['type' => 'string'],
                'remark' => ['type' => 'string'],
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
        $remark = trim($parameters['remark'] ?? '');

        if (!$shopId || empty($remark)) {
            throw new AiValidationException("Shop ID and visit remark are required.");
        }

        $shop = Shop::find($shopId);
        if (!$shop) {
            throw new AiValidationException("Shop with ID {$shopId} was not found.");
        }

        // Find today's latest visit or active visit for this user & shop
        $query = Visit::where('shop_id', $shop->id);
        if ($user->role === 'employee') {
            $query->where('user_id', $user->id);
        }

        $visit = $query->latest()->first();

        $executedVisit = DB::transaction(function () use ($visit, $user, $shop, $remark) {
            if ($visit) {
                $newNotes = ($visit->notes ? $visit->notes . " | " : "") . "[AI Remark by {$user->name}]: {$remark}";
                $visit->update([
                    'notes' => $newNotes,
                ]);
                return $visit;
            } else {
                // If no visit exists yet, create an initial logged visit record
                return Visit::create([
                    'user_id' => $user->id,
                    'shop_id' => $shop->id,
                    'check_in_time' => Carbon::now(),
                    'check_in_lat' => $shop->latitude,
                    'check_in_lng' => $shop->longitude,
                    'purpose' => 'AI_LOGGED_REMARK',
                    'notes' => "[AI Remark by {$user->name}]: {$remark}",
                    'status' => 'STARTED',
                    'is_verified_geofence' => true,
                    'distance_from_shop_meters' => 0.0,
                ]);
            }
        });

        return AiToolResult::success($this->getName(), [
            'success' => true,
            'message' => "Visit remark recorded successfully for '{$shop->name}'.",
            'visit_id' => $executedVisit->id,
            'shop_name' => $shop->name,
            'remark' => $remark,
        ]);
    }
}
