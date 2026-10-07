<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Meter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MeterController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $meters = $request->user()->meters()->latest()->get();

        return response()->json(['data' => $meters->map(
            fn (Meter $meter) => $this->meterData($meter)
        )]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'number' => [
                'required',
                'string',
                'max:40',
                Rule::unique('meters', 'number')
                    ->where('user_id', $request->user()->id),
            ],
            'kind' => ['required', Rule::in(['home', 'business'])],
            'balanceKwh' => [
                'required',
                'numeric',
                'decimal:0,3',
                'min:0',
                'max:999999999',
            ],
        ]);

        $meter = $request->user()->meters()->create([
            'name' => $data['name'],
            'number' => $data['number'],
            'kind' => $data['kind'],
            'balance_kwh' => $data['balanceKwh'],
            'status' => 'pending',
        ]);

        return response()->json(['data' => $this->meterData($meter)], 201);
    }

    public function meterData(Meter $meter): array
    {
        return [
            'id' => (string) $meter->id,
            'name' => $meter->name,
            'number' => $meter->number,
            'balanceKwh' => (float) $meter->balance_kwh,
            'kind' => $meter->kind,
            'status' => $meter->status,
            'lastUpdated' => $meter->last_updated_at?->diffForHumans()
                ?? 'awaiting meter connection',
        ];
    }
}
