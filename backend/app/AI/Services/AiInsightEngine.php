<?php

namespace App\AI\Services;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class AiInsightEngine
{
    protected AiSignalDetector $signalDetector;

    public function __construct(?AiSignalDetector $signalDetector = null)
    {
        $this->signalDetector = $signalDetector ?? new AiSignalDetector();
    }

    /**
     * Gather active, deduplicated operational insights for user
     */
    public function getActiveInsights(User $user): array
    {
        $overdueShops = $this->signalDetector->detectOverdueShops();
        $idleEmployees = $this->signalDetector->detectIdleEmployees();
        $missingAttendance = $this->signalDetector->detectMissingAttendance();

        $allSignals = array_merge($overdueShops, $idleEmployees, $missingAttendance);

        // Filter based on User Role (RBAC & Isolation)
        $filtered = [];
        foreach ($allSignals as $signal) {
            // Admins receive all signals
            if ($user->role === 'admin') {
                $filtered[] = $signal;
                continue;
            }

            // Employees receive only signals pertaining to themselves or shops assigned to them
            if ($signal['entity_type'] === 'employee' && (int)$signal['entity_id'] === (int)$user->id) {
                $filtered[] = $signal;
            } elseif ($signal['entity_type'] === 'shop') {
                $isAssigned = $user->shops()->where('shops.id', $signal['entity_id'])->exists();
                if ($isAssigned) {
                    $filtered[] = $signal;
                }
            }
        }

        // Sort by Severity Priority: CRITICAL > HIGH > MEDIUM > LOW > INFO
        $severityWeight = [
            'CRITICAL' => 4,
            'HIGH' => 3,
            'MEDIUM' => 2,
            'LOW' => 1,
            'INFO' => 0,
        ];

        usort($filtered, function ($a, $b) use ($severityWeight) {
            $wA = $severityWeight[$a['severity']] ?? 0;
            $wB = $severityWeight[$b['severity']] ?? 0;
            return $wB <=> $wA;
        });

        return $filtered;
    }

    /**
     * Generates executive daily operational summary
     */
    public function generateExecutiveSummary(User $user): array
    {
        $insights = $this->getActiveInsights($user);
        
        $criticalCount = 0;
        $highCount = 0;
        $mediumCount = 0;
        $lowCount = 0;

        foreach ($insights as $item) {
            match ($item['severity']) {
                'CRITICAL' => $criticalCount++,
                'HIGH' => $highCount++,
                'MEDIUM' => $mediumCount++,
                default => $lowCount++,
            };
        }

        $totalAlerts = count($insights);
        $statusHealth = $criticalCount > 0 ? 'CRITICAL_ATTENTION_NEEDED' : ($highCount > 0 ? 'ACTION_RECOMMENDED' : 'HEALTHY');

        $summaryText = $totalAlerts === 0
            ? "Operations are running smoothly. All active field agents and stores are within operational baselines."
            : "Detected {$totalAlerts} operational signals ({$highCount} high priority, {$mediumCount} medium). Primary attention recommended for overdue store replenishment and idle agent check-ins.";

        return [
            'status' => $statusHealth,
            'total_alerts' => $totalAlerts,
            'counts' => [
                'critical' => $criticalCount,
                'high' => $highCount,
                'medium' => $mediumCount,
                'low' => $lowCount,
            ],
            'executive_summary' => $summaryText,
            'top_insights' => array_slice($insights, 0, 5),
            'generated_at' => Carbon::now()->toIso8601String(),
        ];
    }

    /**
     * Acknowledge / Dismiss an alert
     */
    public function acknowledgeAlert(User $user, string $alertId, string $action = 'ACKNOWLEDGED'): array
    {
        $cacheKey = "ai_alert_state_{$alertId}";
        Cache::put($cacheKey, [
            'status' => $action,
            'user_id' => $user->id,
            'timestamp' => Carbon::now()->toIso8601String(),
        ], Carbon::now()->addHours(24));

        return [
            'alert_id' => $alertId,
            'status' => $action,
            'user' => $user->name,
            'updated_at' => Carbon::now()->toIso8601String(),
        ];
    }
}
