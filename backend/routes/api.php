<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\LevelController;
use App\Http\Controllers\Api\V1\ProfileController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('levels', [LevelController::class, 'index']);

    Route::post('auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

    Route::middleware(['auth:sanctum', 'device'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [ProfileController::class, 'show']);
        Route::put('me', [ProfileController::class, 'update']);
        Route::post('me/fcm-token', [ProfileController::class, 'fcmToken']);
    });
});
