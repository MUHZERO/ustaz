<?php

use App\Http\Controllers\Panel\CodePrintController;
use App\Models\ActivationCode;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/admin/codes/print/{batch}', CodePrintController::class)
    ->whereUuid('batch')
    ->can('create', ActivationCode::class)
    ->name('codes.print');
