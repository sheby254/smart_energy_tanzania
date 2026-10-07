<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Meter extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'number',
        'kind',
        'balance_kwh',
        'status',
        'last_updated_at',
    ];

    protected function casts(): array
    {
        return [
            'balance_kwh' => 'decimal:3',
            'last_updated_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function outgoingTransfers(): HasMany
    {
        return $this->hasMany(EnergyTransfer::class, 'from_meter_id');
    }

    public function incomingTransfers(): HasMany
    {
        return $this->hasMany(EnergyTransfer::class, 'to_meter_id');
    }
}
