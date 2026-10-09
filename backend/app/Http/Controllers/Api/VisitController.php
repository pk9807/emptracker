<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\Visit;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VisitController extends Controller
{
    /**
     * Calculate Haversine distance in meters
     */
    private function calculateDistance($lat1, $lon1, $lat2, $lon2): float
    {
        $earthRadius = 6371000; // meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * List Visits
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Visit::with(['user:id,name,phone,employee_code,avatar', 'shop']);

        if ($user->role === 'employee') {
            $query->where('user_id', $user->id);
        }

        if ($request->has('date')) {
            $query->whereDate('check_in_time', $request->date);
        }

        if ($request->has('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        $visits = $query->latest('check_in_time')->get()->map(function ($v) {
            return [
                'id' => (string) $v->id,
                'user_id' => (string) $v->user_id,
                'shop_id' => (string) $v->shop_id,
                'employee_name' => $v->user->name ?? '',
                'employee_code' => $v->user->employee_code ?? '',
                'shop_name' => $v->shop->name ?? '',
                'shop_address' => $v->shop->address ?? '',
                'check_in_time' => $v->check_in_time->toIso8601String(),
                'check_out_time' => $v->check_out_time ? $v->check_out_time->toIso8601String() : null,
                'check_in_lat' => (float) $v->check_in_lat,
                'check_in_lng' => (float) $v->check_in_lng,
                'check_out_lat' => $v->check_out_lat ? (float) $v->check_out_lat : null,
                'check_out_lng' => $v->check_out_lng ? (float) $v->check_out_lng : null,
                'photo_url' => $v->photo_url,
                'signature_url' => $v->signature_url,
                'notes' => $v->notes ?? '',
                'purpose' => $v->purpose,
                'outcome' => $v->outcome,
                'order_amount' => (float) $v->order_amount,
                'is_verified_geofence' => (bool) $v->is_verified_geofence,
                'distance_from_shop_meters' => (float) $v->distance_from_shop_meters,
                'status' => $v->status,
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $visits,
        ]);
    }

    /**
     * Start / Check-in to Shop Visit with Geofencing verification
     */
    public function checkIn(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'required|exists:shops,id',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'purpose' => 'nullable|string',
            'photo' => 'nullable|string', // base64 or multipart
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $shop = Shop::findOrFail($request->shop_id);

        $distance = $this->calculateDistance(
            $request->latitude,
            $request->longitude,
            $shop->latitude,
            $shop->longitude
        );

        $isVerified = $distance <= ($shop->geofence_radius_meters ?? 100);

        $photoUrl = null;
        if ($request->filled('photo')) {
            $photoData = $request->photo;
            if (preg_match('/^data:image\/(\w+);base64,/', $photoData, $type)) {
                $photoData = substr($photoData, strpos($photoData, ',') + 1);
                $type = strtolower($type[1]);
                $photoData = base64_decode($photoData);
                $filename = 'visits/' . uniqid() . '.' . $type;
                Storage::disk('public')->put($filename, $photoData);
                $photoUrl = asset('storage/' . $filename);
            }
        }

        $visit = Visit::create([
            'user_id' => $user->id,
            'shop_id' => $shop->id,
            'check_in_time' => Carbon::now(),
            'check_in_lat' => $request->latitude,
            'check_in_lng' => $request->longitude,
            'photo_url' => $photoUrl,
            'purpose' => $request->purpose ?? 'ROUTINE_VISIT',
            'notes' => $request->notes,
            'is_verified_geofence' => $isVerified,
            'distance_from_shop_meters' => round($distance, 1),
            'status' => 'STARTED',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => $isVerified ? 'Checked in to shop successfully' : 'Checked in (Warning: Geofence radius exceeded)',
            'data' => $visit->load('shop'),
        ], 201);
    }

    /**
     * Complete / Check-out from Shop Visit
     */
    public function checkOut(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'outcome' => 'nullable|string',
            'order_amount' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $visit = Visit::findOrFail($id);

        $visit->update([
            'check_out_time' => Carbon::now(),
            'check_out_lat' => $request->latitude,
            'check_out_lng' => $request->longitude,
            'outcome' => $request->outcome ?? 'ORDER_PLACED',
            'order_amount' => $request->order_amount ?? 0.00,
            'notes' => $request->notes ?? $visit->notes,
            'status' => 'COMPLETED',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Visit completed successfully',
            'data' => $visit->load('shop'),
        ]);
    }
}
