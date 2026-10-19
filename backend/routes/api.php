<?php

use App\Http\Controllers\Api\V1\AnnouncementController;
use App\Http\Controllers\Api\V1\AttemptController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\CodeController;
use App\Http\Controllers\Api\V1\HomeController;
use App\Http\Controllers\Api\V1\LectureController;
use App\Http\Controllers\Api\V1\LevelController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ResultController;
use App\Http\Controllers\Api\V1\SubscriptionController;
use App\Http\Controllers\FileController;
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
        Route::get('home', [HomeController::class, '__invoke']);
        Route::get('categories', [CategoryController::class, 'index']);
        Route::get('categories/{category}', [CategoryController::class, 'show'])->whereNumber('category');
        Route::get('lectures/{lecture}', [LectureController::class, 'show'])->whereNumber('lecture');
        Route::post('lectures/{lecture}/progress', [LectureController::class, 'progress'])
            ->whereNumber('lecture')
            ->middleware('throttle:progress');
        Route::get('announcements', [AnnouncementController::class, '__invoke']);
        Route::post('codes/redeem', [CodeController::class, 'redeem'])->middleware('throttle:redeem');
        Route::get('subscriptions', [SubscriptionController::class, 'index']);

        Route::post('assessments/{assessment}/attempts', [AttemptController::class, 'start'])->whereNumber('assessment');
        Route::put('attempts/{attempt}/answers', [AttemptController::class, 'answer'])->whereNumber('attempt')->middleware('throttle:answers');
        Route::post('attempts/{attempt}/submit', [AttemptController::class, 'submit'])->whereNumber('attempt');
        Route::get('attempts/{attempt}/result', [AttemptController::class, 'result'])->whereNumber('attempt');
        Route::get('attempts/{attempt}/review', [AttemptController::class, 'review'])->whereNumber('attempt');
        Route::post('attempts/{attempt}/review-request', [AttemptController::class, 'requestReview'])->whereNumber('attempt');
        Route::get('me/results', [ResultController::class, 'index']);
        Route::get('me/homework', [ResultController::class, 'homework']);
    });
});

Route::get('files/{path}', [FileController::class, 'show'])
    ->name('files.show')
    ->where('path', '.*')
    ->middleware('signed');
