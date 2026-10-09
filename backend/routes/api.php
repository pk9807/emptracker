<?php

use App\Http\Controllers\Api\AiController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\ShopController;
use App\Http\Controllers\Api\VisitController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes for FieldForce Live Tracking System
|--------------------------------------------------------------------------
*/

// Public Endpoints
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});

Route::get('/ai/health', [AiController::class, 'health']);
Route::get('/ai/offline/matrix', [AiController::class, 'offlineMatrix']);

// Authenticated Routes
Route::middleware('auth:sanctum')->group(function () {
    // AI Assistant Endpoints
    Route::prefix('ai')->group(function () {
        Route::post('/chat', [AiController::class, 'chat']);
        Route::post('/actions/confirm', [AiController::class, 'confirmAction']);
        Route::post('/actions/cancel', [AiController::class, 'cancelAction']);
        Route::get('/tools', [AiController::class, 'tools']);
        Route::get('/models', [AiController::class, 'models']);
        Route::get('/insights', [AiController::class, 'insights']);
        Route::get('/insights/summary', [AiController::class, 'executiveSummary']);
        Route::post('/insights/acknowledge', [AiController::class, 'acknowledgeInsight']);
        Route::post('/voice/transcribe', [\App\Http\Controllers\Api\AiVoiceController::class, 'transcribe']);
        Route::get('/training/stats', [\App\Http\Controllers\Api\AiVoiceController::class, 'trainingStats']);
    });

    // Auth & Profile
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Live GPS Location Stream (Ola/Uber/Swiggy radar tracking)
    Route::post('/location/ping', [LocationController::class, 'ping']);
    Route::post('/location/batch', [LocationController::class, 'batch']);
    Route::get('/location/live-radar', [LocationController::class, 'liveRadar']);
    Route::get('/location/history/{employeeId}', [LocationController::class, 'history']);

    // Employee Management (Admin & Manager)
    Route::get('/employees', [EmployeeController::class, 'index']);
    Route::post('/employees', [EmployeeController::class, 'store']);
    Route::get('/employees/{id}', [EmployeeController::class, 'show']);
    Route::post('/employees/{id}/toggle-status', [EmployeeController::class, 'toggleStatus']);

    // Shops & Geofencing
    Route::get('/shops', [ShopController::class, 'index']);
    Route::post('/shops', [ShopController::class, 'store']);
    Route::get('/shops/{id}', [ShopController::class, 'show']);
    Route::put('/shops/{id}', [ShopController::class, 'update']);
    Route::delete('/shops/{id}', [ShopController::class, 'destroy']);

    // Visits Management
    Route::get('/visits', [VisitController::class, 'index']);
    Route::post('/visits/check-in', [VisitController::class, 'checkIn']);
    Route::post('/visits/{id}/check-out', [VisitController::class, 'checkOut']);

    // Attendance Management
    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut']);
    Route::get('/attendance/today', [AttendanceController::class, 'today']);
    Route::get('/attendance/summary', [AttendanceController::class, 'summary']);
});

