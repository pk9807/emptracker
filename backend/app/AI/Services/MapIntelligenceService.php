<?php

namespace App\AI\Services;

use App\Models\EmployeeShop;
use App\Models\LiveLocation;
use App\Models\LocationHistory;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class MapIntelligenceService
{
    /**
     * Calculate Haversine distance between two coordinates in kilometers
     */
    public function calculateDistanceKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusKm = 6371.0;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadiusKm * $c, 2);
    }

    /**
     * Compute deterministic daily route summary from location history & visits
     */
    public function getRouteSummary(int $employeeId, ?string $date = null): array
    {
        $targetDate = $date ? Carbon::parse($date)->toDateString() : Carbon::today()->toDateString();
        $employee = User::find($employeeId);

        if (!$employee) {
            return ['found' => false, 'message' => "Employee #{$employeeId} not found."];
        }

        // 1. Fetch location breadcrumbs ordered chronologically
        $breadcrumbs = LocationHistory::where('user_id', $employeeId)
            ->whereDate('recorded_at', $targetDate)
            ->orderBy('recorded_at', 'asc')
            ->get(['latitude', 'longitude', 'speed', 'recorded_at']);

        $totalDistanceKm = 0.0;
        $idleMinutes = 0;
        $maxSpeedKmh = 0.0;
        $speedSum = 0.0;
        $pointCount = $breadcrumbs->count();

        for ($i = 0; $i < $pointCount - 1; $i++) {
            $p1 = $breadcrumbs[$i];
            $p2 = $breadcrumbs[$i + 1];

            $dist = $this->calculateDistanceKm($p1->latitude, $p1->longitude, $p2->latitude, $p2->longitude);
            $totalDistanceKm += $dist;

            $speed = (float)($p2->speed ?? 0.0);
            if ($speed > $maxSpeedKmh) {
                $maxSpeedKmh = $speed;
            }
            $speedSum += $speed;

            // Idle detection: time delta between points with near-zero movement
            if ($dist < 0.05) {
                $diffMin = Carbon::parse($p1->recorded_at)->diffInMinutes(Carbon::parse($p2->recorded_at));
                if ($diffMin >= 5 && $diffMin <= 120) {
                    $idleMinutes += $diffMin;
                }
            }
        }

        $avgSpeedKmh = $pointCount > 0 ? round($speedSum / $pointCount, 1) : 0.0;

        // 2. Fetch completed visits on this date
        $visits = Visit::with('shop:id,name,address,latitude,longitude')
            ->where('user_id', $employeeId)
            ->whereDate('check_in_time', $targetDate)
            ->orderBy('check_in_time', 'asc')
            ->get();

        $visitedShops = $visits->map(function ($v) {
            $durationMin = $v->check_out_time ? Carbon::parse($v->check_in_time)->diffInMinutes(Carbon::parse($v->check_out_time)) : null;
            return [
                'visit_id' => $v->id,
                'shop_id' => $v->shop_id,
                'shop_name' => $v->shop?->name ?? 'Unknown Shop',
                'check_in_time' => Carbon::parse($v->check_in_time)->format('H:i'),
                'check_out_time' => $v->check_out_time ? Carbon::parse($v->check_out_time)->format('H:i') : 'In Progress',
                'duration_minutes' => $durationMin,
                'is_verified_geofence' => (bool)$v->is_verified_geofence,
                'status' => $v->status,
            ];
        })->toArray();

        // 3. Check live location if available
        $live = LiveLocation::where('user_id', $employeeId)->first();

        return [
            'found' => true,
            'employee_id' => $employee->id,
            'employee_name' => $employee->name,
            'employee_code' => $employee->employee_code,
            'date' => $targetDate,
            'total_gps_points' => $pointCount,
            'total_distance_km' => round($totalDistanceKm, 2),
            'idle_duration_minutes' => $idleMinutes,
            'average_speed_kmh' => $avgSpeedKmh,
            'max_speed_kmh' => round($maxSpeedKmh, 1),
            'total_visits_completed' => count($visitedShops),
            'visited_shops' => $visitedShops,
            'current_online' => (bool)($live?->is_online ?? false),
            'last_ping_at' => $live?->last_ping_at?->toIso8601String(),
        ];
    }

    /**
     * Identify shops not visited for X days
     */
    public function getOverdueShops(int $daysThreshold = 7, ?int $employeeId = null): array
    {
        $thresholdDate = Carbon::now()->subDays($daysThreshold);

        $query = Shop::with(['assignedEmployees:id,name', 'visits' => function ($q) {
            $q->latest('check_in_time')->limit(1);
        }]);

        if ($employeeId !== null) {
            $query->whereHas('assignedEmployees', function ($q) use ($employeeId) {
                $q->where('user_id', $employeeId);
            });
        }

        $shops = $query->get();
        $overdue = [];

        foreach ($shops as $shop) {
            $lastVisit = $shop->visits->first();
            $lastVisitTime = $lastVisit?->check_in_time ? Carbon::parse($lastVisit->check_in_time) : null;

            $isOverdue = false;
            $daysSince = null;

            if (!$lastVisitTime) {
                $isOverdue = true;
                $daysSince = 999; // Never visited
            } elseif ($lastVisitTime->lessThan($thresholdDate)) {
                $isOverdue = true;
                $daysSince = (int)Carbon::now()->diffInDays($lastVisitTime);
            }

            if ($isOverdue) {
                $overdue[] = [
                    'shop_id' => $shop->id,
                    'name' => $shop->name,
                    'owner_name' => $shop->owner_name ?? '',
                    'address' => $shop->address ?? '',
                    'latitude' => (float)$shop->latitude,
                    'longitude' => (float)$shop->longitude,
                    'days_since_last_visit' => $daysSince === 999 ? 'Never Visited' : $daysSince,
                    'last_visit_date' => $lastVisitTime?->toDateString() ?? 'Never',
                    'assigned_employees' => $shop->assignedEmployees->pluck('name')->toArray(),
                ];
            }
        }

        // Sort by most overdue first
        usort($overdue, function ($a, $b) {
            $dA = $a['days_since_last_visit'] === 'Never Visited' ? 9999 : (int)$a['days_since_last_visit'];
            $dB = $b['days_since_last_visit'] === 'Never Visited' ? 9999 : (int)$b['days_since_last_visit'];
            return $dB <=> $dA;
        });

        return [
            'threshold_days' => $daysThreshold,
            'total_overdue' => count($overdue),
            'shops' => array_slice($overdue, 0, 15),
        ];
    }

    /**
     * Compute deterministic next shop recommendation based on proximity and urgency
     */
    public function recommendNextShop(int $employeeId, ?float $currentLat = null, ?float $currentLng = null): array
    {
        $employee = User::find($employeeId);
        if (!$employee) {
            return ['found' => false, 'message' => "Employee not found."];
        }

        // If coordinates not passed, get from LiveLocation
        if ($currentLat === null || $currentLng === null) {
            $live = LiveLocation::where('user_id', $employeeId)->first();
            $currentLat = $live?->latitude ?? 26.4499; // Default Kanpur center if unavailable
            $currentLng = $live?->longitude ?? 80.3319;
        }

        // Fetch assigned shops
        $assignedShops = Shop::whereHas('assignedEmployees', function ($q) use ($employeeId) {
            $q->where('user_id', $employeeId);
        })->with(['visits' => function ($q) {
            $q->latest('check_in_time')->limit(1);
        }])->get();

        if ($assignedShops->isEmpty()) {
            return [
                'found' => false,
                'message' => "No assigned shops found for employee {$employee->name}.",
            ];
        }

        // Filter out shops visited today
        $today = Carbon::today()->toDateString();
        $todayVisitedIds = Visit::where('user_id', $employeeId)
            ->whereDate('check_in_time', $today)
            ->pluck('shop_id')
            ->toArray();

        $candidates = [];

        foreach ($assignedShops as $shop) {
            if (in_array($shop->id, $todayVisitedIds)) {
                continue; // Already visited today
            }

            $distKm = $this->calculateDistanceKm($currentLat, $currentLng, (float)$shop->latitude, (float)$shop->longitude);

            $lastVisit = $shop->visits->first();
            $daysSince = $lastVisit?->check_in_time ? (int)Carbon::now()->diffInDays(Carbon::parse($lastVisit->check_in_time)) : 30;

            // Deterministic Urgency Score: (Days Since Visit * 2.0) - (Distance in KM * 1.2)
            $score = ($daysSince * 2.0) - ($distKm * 1.2);

            $candidates[] = [
                'shop_id' => $shop->id,
                'name' => $shop->name,
                'owner_name' => $shop->owner_name ?? '',
                'address' => $shop->address ?? '',
                'latitude' => (float)$shop->latitude,
                'longitude' => (float)$shop->longitude,
                'distance_km' => $distKm,
                'days_since_last_visit' => $daysSince,
                'score' => round($score, 2),
                'reason' => "Distance: {$distKm} km away • Unvisited for {$daysSince} days",
            ];
        }

        if (empty($candidates)) {
            return [
                'found' => true,
                'all_completed' => true,
                'message' => "All {$assignedShops->count()} assigned shops have been visited today!",
                'recommended_shop' => null,
                'pending_candidates' => [],
            ];
        }

        // Sort by highest deterministic score first
        usort($candidates, fn($a, $b) => $b['score'] <=> $a['score']);
        $bestChoice = $candidates[0];

        return [
            'found' => true,
            'all_completed' => false,
            'employee_name' => $employee->name,
            'total_pending' => count($candidates),
            'recommended_shop' => $bestChoice,
            'pending_candidates' => array_slice($candidates, 0, 5),
        ];
    }

    /**
     * Compute area coverage summary
     */
    public function getAreaCoverageSummary(float $centerLat, float $centerLng, float $radiusKm = 15.0): array
    {
        $shops = Shop::all(['id', 'name', 'latitude', 'longitude', 'status']);
        $inAreaShops = [];
        $totalCovered = 0;

        $sevenDaysAgo = Carbon::now()->subDays(7);

        foreach ($shops as $shop) {
            $dist = $this->calculateDistanceKm($centerLat, $centerLng, (float)$shop->latitude, (float)$shop->longitude);
            if ($dist <= $radiusKm) {
                $hasRecentVisit = Visit::where('shop_id', $shop->id)
                    ->where('check_in_time', '>=', $sevenDaysAgo)
                    ->exists();

                if ($hasRecentVisit) {
                    $totalCovered++;
                }

                $inAreaShops[] = [
                    'shop_id' => $shop->id,
                    'name' => $shop->name,
                    'distance_km' => $dist,
                    'visited_last_7_days' => $hasRecentVisit,
                ];
            }
        }

        $totalInArea = count($inAreaShops);
        $coveragePct = $totalInArea > 0 ? round(($totalCovered / $totalInArea) * 100, 1) : 0.0;

        return [
            'center_coordinates' => ['latitude' => $centerLat, 'longitude' => $centerLng],
            'radius_km' => $radiusKm,
            'total_shops_in_area' => $totalInArea,
            'covered_shops_count' => $totalCovered,
            'pending_shops_count' => $totalInArea - $totalCovered,
            'coverage_percentage' => $coveragePct,
            'sample_shops' => array_slice($inAreaShops, 0, 8),
        ];
    }
}
