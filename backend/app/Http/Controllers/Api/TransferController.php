<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EnergyTransfer;
use App\Models\Meter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class TransferController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transfers = $request->user()->energyTransfers()->latest()->get();

        return response()->json(['data' => $transfers->map(
            fn (EnergyTransfer $transfer) => $this->transferData($transfer)
        )]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'fromMeterId' => ['required', 'integer', 'different:toMeterId'],
            'toMeterId' => ['required', 'integer'],
            'amountKwh' => [
                'required',
                'numeric',
                'decimal:0,3',
                'gt:0',
                'max:999999999',
            ],
        ]);

        $transfer = DB::transaction(function () use ($request, $data) {
            $meterIds = [(int) $data['fromMeterId'], (int) $data['toMeterId']];
            sort($meterIds);

            $lockedMeters = Meter::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('id', $meterIds)
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            $fromMeter = $lockedMeters->get((int) $data['fromMeterId']);
            $toMeter = $lockedMeters->get((int) $data['toMeterId']);
            if (! $fromMeter || ! $toMeter) {
                throw ValidationException::withMessages([
                    'meters' => ['Both meters must belong to your account.'],
                ]);
            }

            $amount = round((float) $data['amountKwh'], 3);
            if ((float) $fromMeter->balance_kwh < $amount) {
                throw ValidationException::withMessages([
                    'amountKwh' => ['The source meter has insufficient units.'],
                ]);
            }

            $fromMeter->balance_kwh = round(
                (float) $fromMeter->balance_kwh - $amount,
                3
            );
            $toMeter->balance_kwh = round(
                (float) $toMeter->balance_kwh + $amount,
                3
            );
            $fromMeter->save();
            $toMeter->save();

            return EnergyTransfer::create([
                'user_id' => $request->user()->id,
                'from_meter_id' => $fromMeter->id,
                'to_meter_id' => $toMeter->id,
                'reference' => 'SE-'.Str::upper(Str::random(16)),
                'from_meter_name' => $fromMeter->name,
                'from_meter_number' => $fromMeter->number,
                'to_meter_name' => $toMeter->name,
                'to_meter_number' => $toMeter->number,
                'amount_kwh' => $amount,
                'status' => 'recorded',
            ]);
        });

        $updatedMeters = Meter::query()
            ->whereIn('id', [$transfer->from_meter_id, $transfer->to_meter_id])
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => [
                'transfer' => $this->transferData($transfer),
                'meters' => $updatedMeters->map(
                    fn (Meter $meter) => app(MeterController::class)->meterData($meter)
                ),
            ],
        ], 201);
    }

    public function transferData(EnergyTransfer $transfer): array
    {
        return [
            'id' => $transfer->reference,
            'fromMeterId' => (string) $transfer->from_meter_id,
            'fromMeterName' => $transfer->from_meter_name,
            'fromMeterNumber' => $transfer->from_meter_number,
            'toMeterId' => (string) $transfer->to_meter_id,
            'toMeterName' => $transfer->to_meter_name,
            'toMeterNumber' => $transfer->to_meter_number,
            'amountKwh' => (float) $transfer->amount_kwh,
            'createdAt' => $transfer->created_at->toIso8601String(),
        ];
    }
}
