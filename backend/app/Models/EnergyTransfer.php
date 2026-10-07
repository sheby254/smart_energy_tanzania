<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EnergyTransfer extends Model
{
    protected $fillable = [
        'user_id',
        'from_meter_id',
        'to_meter_id',
        'reference',
        'from_meter_name',
        'from_meter_number',
        'to_meter_name',
        'to_meter_number',
        'amount_kwh',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'amount_kwh' => 'decimal:3',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function fromMeter(): BelongsTo
    {
        return $this->belongsTo(Meter::class, 'from_meter_id');
    }

    public function toMeter(): BelongsTo
    {
        return $this->belongsTo(Meter::class, 'to_meter_id');
    }
}
