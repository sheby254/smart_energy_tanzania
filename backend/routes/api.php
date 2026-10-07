<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MeterController;
use App\Http\Controllers\Api\TransferController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,1');
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', function (Request $request) {
        $meterController = app(MeterController::class);

        return response()->json([
            'data' => [
                'meters' => $request->user()->meters()->latest()->get()
                    ->map(fn ($meter) => $meterController->meterData($meter)),
                'transfers' => $request->user()->energyTransfers()->latest()->get()
                    ->map(fn ($transfer) => app(TransferController::class)->transferData($transfer)),
            ],
        ]);
    });
    Route::get('/meters', [MeterController::class, 'index']);
    Route::post('/meters', [MeterController::class, 'store']);
    Route::get('/transfers', [TransferController::class, 'index']);
    Route::post('/transfers', [TransferController::class, 'store']);
});
