<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class EmployeeController extends Controller
{
    /**
     * List all employees with their current live duty and location status
     */
    public function index(Request $request): JsonResponse
    {
        $today = Carbon::today()->toDateString();

        $employees = User::where('role', '!=', 'admin')
            ->with([
                'liveLocation',
                'shops',
                'attendances' => function ($q) use ($today) {
                    $q->where('date', $today);
                },
                'visits' => function ($q) use ($today) {
                    $q->whereDate('check_in_time', $today);
                }
            ])
            ->latest()
            ->get()
            ->map(function ($emp) {
                $todayAttendance = $emp->attendances->first();
                $isOnDuty = $todayAttendance && $todayAttendance->check_out_time === null;

                return [
                    'id' => (string) $emp->id,
                    'name' => $emp->name,
                    'email' => $emp->email,
                    'phone' => $emp->phone ?? '',
                    'employee_code' => $emp->employee_code ?? 'EMP-' . str_pad($emp->id, 3, '0', STR_PAD_LEFT),
                    'designation' => $emp->designation ?? 'Field Executive',
                    'department' => $emp->department ?? 'Operations',
                    'avatar' => $emp->avatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                    'is_active' => (bool) $emp->is_active,
                    'is_on_duty' => $isOnDuty,
                    'assigned_shops_count' => $emp->shops->count(),
                    'today_visits_count' => $emp->visits->count(),
                    'live_location' => $emp->liveLocation ? [
                        'latitude' => $emp->liveLocation->latitude,
                        'longitude' => $emp->liveLocation->longitude,
                        'accuracy' => $emp->liveLocation->accuracy,
                        'speed' => $emp->liveLocation->speed,
                        'heading' => $emp->liveLocation->heading,
                        'battery_level' => $emp->liveLocation->battery_level,
                        'activity_type' => $emp->liveLocation->activity_type,
                        'is_online' => $emp->liveLocation->is_online,
                        'last_ping_at' => $emp->liveLocation->last_ping_at->toIso8601String(),
                    ] : null,
                ];
            });

        return response()->json([
            'status' => 'success',
            'data' => $employees,
        ]);
    }

    /**
     * Admin Registers New Employee
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'phone' => 'nullable|string|max:20',
            'employee_code' => 'nullable|string|unique:users',
            'designation' => 'nullable|string|max:100',
            'department' => 'nullable|string|max:100',
            'assigned_shop_ids' => 'nullable|array',
            'assigned_shop_ids.*' => 'exists:shops,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $code = $request->employee_code ?: 'EMP-' . rand(100, 999);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'employee',
            'phone' => $request->phone,
            'employee_code' => $code,
            'designation' => $request->designation ?? 'Field Executive',
            'department' => $request->department ?? 'Sales & Field Force',
            'avatar' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            'is_active' => true,
        ]);

        if ($request->has('assigned_shop_ids')) {
            $user->shops()->sync($request->assigned_shop_ids);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Employee registered successfully',
            'data' => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'employee_code' => $user->employee_code,
                'designation' => $user->designation,
                'department' => $user->department,
                'is_active' => $user->is_active,
            ],
        ], 201);
    }

    /**
     * Show single employee details
     */
    public function show(string $id): JsonResponse
    {
        $employee = User::with(['liveLocation', 'shops', 'attendances', 'visits.shop'])->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'data' => $employee,
        ]);
    }

    /**
     * Toggle employee active status
     */
    public function toggleStatus(string $id): JsonResponse
    {
        $employee = User::findOrFail($id);
        $employee->is_active = !$employee->is_active;
        $employee->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Employee status updated',
            'data' => [
                'is_active' => $employee->is_active,
            ],
        ]);
    }
}
