<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\LiveLocation;
use App\Models\LocationHistory;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LocationController extends Controller
{
    /**
     * Update Live GPS Telemetry from Employee App (Ola/Uber/Swiggy Real-time Ping)
     */
    public function ping(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'accuracy' => 'nullable|numeric',
            'speed' => 'nullable|numeric',
            'heading' => 'nullable|numeric',
            'altitude' => 'nullable|numeric',
            'battery_level' => 'nullable|integer',
            'is_mocked' => 'nullable|boolean',
            'activity_type' => 'nullable|string',
            'recorded_at' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $recordedAt = $request->recorded_at ? Carbon::parse($request->recorded_at) : Carbon::now();

        // 1. Upsert Live Location
        $live = LiveLocation::updateOrCreate(
            ['user_id' => $user->id],
            [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'accuracy' => $request->accuracy ?? 5.0,
                'speed' => $request->speed ?? 0.0,
                'heading' => $request->heading ?? 0.0,
                'altitude' => $request->altitude ?? 0.0,
                'battery_level' => $request->battery_level ?? 100,
                'is_mocked' => $request->is_mocked ?? false,
                'activity_type' => $request->activity_type ?? 'STILL',
                'is_online' => true,
                'last_ping_at' => Carbon::now(),
            ]
        );

        // 2. Append to Location History trail
        LocationHistory::create([
            'user_id' => $user->id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'speed' => $request->speed ?? 0.0,
            'heading' => $request->heading ?? 0.0,
            'accuracy' => $request->accuracy ?? 5.0,
            'battery_level' => $request->battery_level ?? 100,
            'recorded_at' => $recordedAt,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Location updated successfully',
            'data' => [
                'user_id' => $user->id,
                'latitude' => $live->latitude,
                'longitude' => $live->longitude,
                'last_ping_at' => $live->last_ping_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Batch sync offline buffered points
     */
    public function batch(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'locations' => 'required|array',
            'locations.*.latitude' => 'required|numeric',
            'locations.*.longitude' => 'required|numeric',
            'locations.*.speed' => 'nullable|numeric',
            'locations.*.heading' => 'nullable|numeric',
            'locations.*.accuracy' => 'nullable|numeric',
            'locations.*.battery_level' => 'nullable|integer',
            'locations.*.recorded_at' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $records = [];
        $lastPoint = null;

        foreach ($request->locations as $loc) {
            $recordedAt = Carbon::parse($loc['recorded_at']);
            $records[] = [
                'user_id' => $user->id,
                'latitude' => $loc['latitude'],
                'longitude' => $loc['longitude'],
                'speed' => $loc['speed'] ?? 0.0,
                'heading' => $loc['heading'] ?? 0.0,
                'accuracy' => $loc['accuracy'] ?? 5.0,
                'battery_level' => $loc['battery_level'] ?? 100,
                'recorded_at' => $recordedAt,
                'created_at' => now(),
                'updated_at' => now(),
            ];
            $lastPoint = $loc;
        }

        LocationHistory::insert($records);

        if ($lastPoint) {
            LiveLocation::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'latitude' => $lastPoint['latitude'],
                    'longitude' => $lastPoint['longitude'],
                    'accuracy' => $lastPoint['accuracy'] ?? 5.0,
                    'speed' => $lastPoint['speed'] ?? 0.0,
                    'heading' => $lastPoint['heading'] ?? 0.0,
                    'battery_level' => $lastPoint['battery_level'] ?? 100,
                    'is_online' => true,
                    'last_ping_at' => Carbon::now(),
                ]
            );
        }

        return response()->json([
            'status' => 'success',
            'message' => count($records) . ' buffered locations synced successfully',
        ]);
    }

    /**
     * Get All Active Employees Live Radar Stream (Ola/Uber/Swiggy Map Radar)
     */
    public function liveRadar(Request $request): JsonResponse
    {
        $today = Carbon::today()->toDateString();

        $liveLocations = LiveLocation::with(['user.shops', 'user.attendances' => function ($q) use ($today) {
            $q->where('date', $today);
        }])
        ->whereHas('user', function ($q) {
            $q->where('is_active', true);
        })
        ->get()
        ->map(function ($live) {
            $user = $live->user;
            $todayAttendance = $user->attendances->first();
            $isOnDuty = $todayAttendance && $todayAttendance->check_out_time === null;

            return [
                'employee_id' => (string) $user->id,
                'name' => $user->name,
                'phone' => $user->phone ?? '',
                'employee_code' => $user->employee_code ?? 'EMP-' . $user->id,
                'designation' => $user->designation ?? 'Field Officer',
                'avatar' => $user->avatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                'is_on_duty' => $isOnDuty,
                'is_online' => (bool) $live->is_online,
                'latitude' => (float) $live->latitude,
                'longitude' => (float) $live->longitude,
                'accuracy' => (float) $live->accuracy,
                'speed' => (float) $live->speed,
                'heading' => (float) $live->heading,
                'altitude' => (float) $live->altitude,
                'battery_level' => (int) $live->battery_level,
                'activity_type' => $live->activity_type,
                'is_mocked' => (bool) $live->is_mocked,
                'last_ping_at' => $live->last_ping_at ? $live->last_ping_at->toIso8601String() : null,
                'assigned_shops_count' => $user->shops->count(),
            ];
        });

        return response()->json([
            'status' => 'success',
            'timestamp' => now()->toIso8601String(),
            'total_active' => $liveLocations->count(),
            'data' => $liveLocations,
        ]);
    }

    /**
     * Get Route History Polyline for Employee
     */
    public function history(Request $request, string $employeeId): JsonResponse
    {
        $date = $request->query('date', Carbon::today()->toDateString());

        $breadcrumbs = LocationHistory::where('user_id', $employeeId)
            ->whereDate('recorded_at', $date)
            ->orderBy('recorded_at', 'asc')
            ->get()
            ->map(function ($loc) {
                return [
                    'latitude' => (float) $loc->latitude,
                    'longitude' => (float) $loc->longitude,
                    'speed' => (float) $loc->speed,
                    'heading' => (float) $loc->heading,
                    'accuracy' => (float) $loc->accuracy,
                    'battery_level' => (int) $loc->battery_level,
                    'recorded_at' => $loc->recorded_at->toIso8601String(),
                ];
            });

        return response()->json([
            'status' => 'success',
            'employee_id' => $employeeId,
            'date' => $date,
            'total_points' => $breadcrumbs->count(),
            'data' => $breadcrumbs,
        ]);
    }
}
