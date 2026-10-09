<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AttendanceController extends Controller
{
    /**
     * Start Duty (Punch In)
     */
    public function checkIn(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'address' => 'nullable|string',
            'battery_level' => 'nullable|integer',
            'photo' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $today = Carbon::today()->toDateString();

        $existing = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        if ($existing && $existing->check_out_time === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Duty already started today',
                'data' => $existing,
            ], 400);
        }

        $photoUrl = null;
        if ($request->filled('photo')) {
            $photoData = $request->photo;
            if (preg_match('/^data:image\/(\w+);base64,/', $photoData, $type)) {
                $photoData = substr($photoData, strpos($photoData, ',') + 1);
                $type = strtolower($type[1]);
                $photoData = base64_decode($photoData);
                $filename = 'attendance/' . uniqid() . '.' . $type;
                Storage::disk('public')->put($filename, $photoData);
                $photoUrl = asset('storage/' . $filename);
            }
        }

        $attendance = Attendance::updateOrCreate(
            [
                'user_id' => $user->id,
                'date' => $today,
            ],
            [
                'check_in_time' => Carbon::now(),
                'check_out_time' => null,
                'check_in_lat' => $request->latitude,
                'check_in_lng' => $request->longitude,
                'check_in_address' => $request->address ?? 'Live GPS Location',
                'check_in_photo_url' => $photoUrl,
                'battery_level' => $request->battery_level ?? 100,
                'status' => 'ON_DUTY',
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Duty started successfully. GPS background tracking active.',
            'data' => $attendance,
        ], 201);
    }

    /**
     * End Duty (Punch Out)
     */
    public function checkOut(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'address' => 'nullable|string',
            'total_distance_km' => 'nullable|numeric',
            'photo' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $today = Carbon::today()->toDateString();

        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        if (!$attendance) {
            return response()->json([
                'status' => 'error',
                'message' => 'No active check-in found for today',
            ], 404);
        }

        $photoUrl = null;
        if ($request->filled('photo')) {
            $photoData = $request->photo;
            if (preg_match('/^data:image\/(\w+);base64,/', $photoData, $type)) {
                $photoData = substr($photoData, strpos($photoData, ',') + 1);
                $type = strtolower($type[1]);
                $photoData = base64_decode($photoData);
                $filename = 'attendance/' . uniqid() . '.' . $type;
                Storage::disk('public')->put($filename, $photoData);
                $photoUrl = asset('storage/' . $filename);
            }
        }

        $attendance->update([
            'check_out_time' => Carbon::now(),
            'check_out_lat' => $request->latitude,
            'check_out_lng' => $request->longitude,
            'check_out_address' => $request->address ?? 'Live GPS Location',
            'check_out_photo_url' => $photoUrl,
            'total_distance_km' => $request->total_distance_km ?? $attendance->total_distance_km,
            'status' => 'COMPLETED',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Duty ended successfully',
            'data' => $attendance,
        ]);
    }

    /**
     * Today's Attendance Status
     */
    public function today(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = Carbon::today()->toDateString();

        $attendance = Attendance::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        return response()->json([
            'status' => 'success',
            'data' => [
                'is_on_duty' => $attendance && $attendance->check_out_time === null,
                'attendance' => $attendance,
            ],
        ]);
    }

    /**
     * Attendance Summary (for Admin Dashboard)
     */
    public function summary(Request $request): JsonResponse
    {
        $today = Carbon::today()->toDateString();

        $attendances = Attendance::with('user:id,name,phone,employee_code,avatar')
            ->where('date', $today)
            ->get();

        $totalPresent = $attendances->count();
        $totalOnDuty = $attendances->whereNull('check_out_time')->count();
        $totalCompleted = $attendances->whereNotNull('check_out_time')->count();

        return response()->json([
            'status' => 'success',
            'data' => [
                'date' => $today,
                'total_present' => $totalPresent,
                'total_on_duty' => $totalOnDuty,
                'total_completed' => $totalCompleted,
                'records' => $attendances,
            ],
        ]);
    }
}
