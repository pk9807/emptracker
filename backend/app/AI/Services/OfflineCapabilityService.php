<?php

namespace App\AI\Services;

use App\AI\Enums\UserRole;

class OfflineCapabilityService
{
    /**
     * Complete Offline Capability Matrix
     */
    protected array $capabilityMatrix = [
        'general_faq' => [
            'is_offline_capable' => true,
            'requires_fresh_telemetry' => false,
            'roles' => ['admin', 'employee', 'manager'],
            'description' => 'EmpTracker app navigation, policy rules, and feature guide.',
        ],
        'cached_route_guidance' => [
            'is_offline_capable' => true,
            'requires_fresh_telemetry' => false,
            'roles' => ['admin', 'employee'],
            'description' => 'Offline review of previously synced daily assigned stores.',
        ],
        'live_employee_location' => [
            'is_offline_capable' => false,
            'requires_fresh_telemetry' => true,
            'roles' => ['admin', 'employee'],
            'description' => 'Real-time GPS coordinate telemetry requires an active server connection.',
        ],
        'live_route_telemetry' => [
            'is_offline_capable' => false,
            'requires_fresh_telemetry' => true,
            'roles' => ['admin', 'employee'],
            'description' => 'Active day distance and speed calculation requires live GPS stream.',
        ],
        'write_actions' => [
            'is_offline_capable' => false,
            'requires_fresh_telemetry' => true,
            'roles' => ['admin', 'employee'],
            'description' => 'Task assignments and notes require atomic server validation and signature.',
        ],
    ];

    /**
     * Check if a specific query intent is supported offline
     */
    public function getCapability(string $capabilityKey): ?array
    {
        return $this->capabilityMatrix[$capabilityKey] ?? null;
    }

    /**
     * Full capability matrix for client introspection
     */
    public function getMatrix(): array
    {
        return $this->capabilityMatrix;
    }

    /**
     * Produce clean offline explanation message when online is required
     */
    public function getOfflineUnavailableNotice(string $capabilityKey, string $lang = 'en'): string
    {
        $isHindiOrHinglish = in_array($lang, ['hi', 'hinglish'], true);

        return match ($capabilityKey) {
            'live_employee_location' => $isHindiOrHinglish
                ? "Live location dekhne ke liye internet connection zaroori hai. Offline mode me live location available nahi hai."
                : "Live employee location requires an active internet connection. It is not available in offline mode.",
            'write_actions' => $isHindiOrHinglish
                ? "Task assign ya record update karne ke liye server connection zaroori hai. Offline write actions allowed nahi hain."
                : "Task assignment and updates require a live server connection. Offline write actions are disabled.",
            default => $isHindiOrHinglish
                ? "Is jankari ke liye server se connect hona zaroori hai."
                : "This information requires a current server connection.",
        };
    }
}
