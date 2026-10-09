<?php

namespace App\AI\Services;

use App\Models\Attendance;
use App\Models\LiveLocation;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;

class AiSignalDetector
{
    /**
     * Detect overdue retail shops
     */
    public function detectOverdueShops(?int $days = null): array
    {
        $threshold = $days ?? (int)config('ai.proactive.shop_overdue_days', 7);
        $signals = [];

        $shops = Shop::where('status', 'ACTIVE')->get();
        foreach ($shops as $shop) {
            $lastVisit = Visit::where('shop_id', $shop->id)
                ->where('status', 'COMPLETED')
                ->latest('check_in_time')
                ->first();

            $daysSince = $lastVisit 
                ? Carbon::parse($lastVisit->check_in_time)->diffInDays(Carbon::now())
                : 30; // Default 30 days if unvisited

            if ($daysSince >= $threshold) {
                $severity = $daysSince >= 21 ? 'CRITICAL' : ($daysSince >= 14 ? 'HIGH' : 'MEDIUM');

                $signals[] = [
                    'id' => "shop_overdue_{$shop->id}",
                    'signal_type' => 'SHOP_OVERDUE',
                    'severity' => $severity,
                    'entity_type' => 'shop',
                    'entity_id' => $shop->id,
                    'entity_name' => $shop->name,
                    'title' => "Shop Visit Overdue: {$shop->name}",
                    'facts' => [
                        'shop_id' => $shop->id,
                        'shop_name' => $shop->name,
                        'days_since_last_visit' => $daysSince,
                        'threshold_days' => $threshold,
                        'address' => $shop->address,
                        'latitude' => (float)$shop->latitude,
                        'longitude' => (float)$shop->longitude,
                    ],
                    'recommendation' => "Assign an immediate field visit to {$shop->name} to maintain retail replenishment.",
                    'status' => 'ACTIVE',
                    'created_at' => Carbon::now()->toIso8601String(),
                ];
            }
        }

        return $signals;
    }

    /**
     * Detect idle employees with prolonged stationary periods
     */
    public function detectIdleEmployees(?int $idleMinutes = null): array
    {
        $threshold = $idleMinutes ?? (int)config('ai.proactive.idle_threshold_minutes', 30);
        $signals = [];

        $liveLocs = LiveLocation::with('user')->where('is_online', true)->get();
        foreach ($liveLocs as $loc) {
            if (!$loc->user || $loc->user->role !== 'employee') continue;

            $minutesSincePing = Carbon::parse($loc->last_ping_at)->diffInMinutes(Carbon::now());
            $isStationary = in_array($loc->activity_type, ['STILL', 'UNKNOWN'], true) || (float)$loc->speed < 1.0;

            if ($isStationary && $minutesSincePing >= $threshold) {
                $severity = $minutesSincePing >= 60 ? 'HIGH' : 'MEDIUM';

                $signals[] = [
                    'id' => "emp_idle_{$loc->user_id}",
                    'signal_type' => 'EMPLOYEE_IDLE_TOO_LONG',
                    'severity' => $severity,
                    'entity_type' => 'employee',
                    'entity_id' => $loc->user_id,
                    'entity_name' => $loc->user->name,
                    'title' => "Stationary Inactivity: {$loc->user->name}",
                    'facts' => [
                        'employee_id' => $loc->user_id,
                        'employee_name' => $loc->user->name,
                        'idle_minutes' => $minutesSincePing,
                        'battery_level' => $loc->battery_level,
                        'latitude' => (float)$loc->latitude,
                        'longitude' => (float)$loc->longitude,
                    ],
                    'recommendation' => "Review field telemetry or send an operational check-in reminder to {$loc->user->name}.",
                    'status' => 'ACTIVE',
                    'created_at' => Carbon::now()->toIso8601String(),
                ];
            }
        }

        return $signals;
    }

    /**
     * Detect missing attendance for today's active workforce
     */
    public function detectMissingAttendance(): array
    {
        $signals = [];
        $today = Carbon::today()->toDateString();

        $employees = User::where('role', 'employee')->where('is_active', true)->get();
        foreach ($employees as $emp) {
            $hasAttendance = Attendance::where('user_id', $emp->id)->where('date', $today)->exists();

            if (!$hasAttendance) {
                $signals[] = [
                    'id' => "missing_attendance_{$emp->id}",
                    'signal_type' => 'MISSING_ATTENDANCE',
                    'severity' => 'LOW',
                    'entity_type' => 'employee',
                    'entity_id' => $emp->id,
                    'entity_name' => $emp->name,
                    'title' => "Pending Duty Punch In: {$emp->name}",
                    'facts' => [
                        'employee_id' => $emp->id,
                        'employee_name' => $emp->name,
                        'date' => $today,
                        'department' => $emp->department,
                    ],
                    'recommendation' => "Remind {$emp->name} to complete duty punch in on the mobile app.",
                    'status' => 'ACTIVE',
                    'created_at' => Carbon::now()->toIso8601String(),
                ];
            }
        }

        return $signals;
    }
}
