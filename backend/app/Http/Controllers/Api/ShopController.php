<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ShopController extends Controller
{
    /**
     * List all shops (or shops assigned to the authenticated employee)
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Shop::with('assignedEmployees:id,name,phone,employee_code');

        // If employee, filter to their assigned shops if requested or return all
        if ($user->role === 'employee' && $request->has('assigned_only')) {
            $query->whereHas('assignedEmployees', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            });
        }

        $shops = $query->latest()->get()->map(function ($shop) {
            return [
                'id' => (string) $shop->id,
                'name' => $shop->name,
                'owner_name' => $shop->owner_name ?? '',
                'phone' => $shop->phone ?? '',
                'address' => $shop->address ?? '',
                'latitude' => (float) $shop->latitude,
                'longitude' => (float) $shop->longitude,
                'geofence_radius_meters' => (int) $shop->geofence_radius_meters,
                'qr_code' => $shop->qr_code ?? '',
                'category' => $shop->category ?? 'RETAIL',
                'status' => $shop->status ?? 'ACTIVE',
                'photo_url' => $shop->photo_url,
                'assigned_employees' => $shop->assignedEmployees,
                'created_at' => $shop->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $shops,
        ]);
    }

    /**
     * Create New Shop
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'owner_name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'geofence_radius_meters' => 'nullable|integer|min:20|max:1000',
            'qr_code' => 'nullable|string|unique:shops',
            'category' => 'nullable|string',
            'assigned_employee_ids' => 'nullable|array',
            'assigned_employee_ids.*' => 'exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $qr = $request->qr_code ?: 'SHOP-' . strtoupper(uniqid());

        $shop = Shop::create([
            'name' => $request->name,
            'owner_name' => $request->owner_name,
            'phone' => $request->phone,
            'address' => $request->address,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'geofence_radius_meters' => $request->geofence_radius_meters ?? 100,
            'qr_code' => $qr,
            'category' => $request->category ?? 'RETAIL',
            'status' => 'ACTIVE',
            'created_by' => $request->user()->id,
        ]);

        if ($request->has('assigned_employee_ids')) {
            $shop->assignedEmployees()->sync($request->assigned_employee_ids);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Shop created successfully',
            'data' => $shop->load('assignedEmployees'),
        ], 201);
    }

    /**
     * Show single shop
     */
    public function show(string $id): JsonResponse
    {
        $shop = Shop::with('assignedEmployees')->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'data' => $shop,
        ]);
    }

    /**
     * Update Shop
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $shop = Shop::findOrFail($id);

        $shop->update($request->only([
            'name',
            'owner_name',
            'phone',
            'address',
            'latitude',
            'longitude',
            'geofence_radius_meters',
            'category',
            'status',
        ]));

        if ($request->has('assigned_employee_ids')) {
            $shop->assignedEmployees()->sync($request->assigned_employee_ids);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Shop updated successfully',
            'data' => $shop->load('assignedEmployees'),
        ]);
    }

    /**
     * Delete Shop
     */
    public function destroy(string $id): JsonResponse
    {
        $shop = Shop::findOrFail($id);
        $shop->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Shop deleted successfully',
        ]);
    }
}
