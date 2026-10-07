<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('energy_transfers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('from_meter_id')->constrained('meters')->restrictOnDelete();
            $table->foreignId('to_meter_id')->constrained('meters')->restrictOnDelete();
            $table->string('reference', 32)->unique();
            $table->string('from_meter_name', 80);
            $table->string('from_meter_number', 40);
            $table->string('to_meter_name', 80);
            $table->string('to_meter_number', 40);
            $table->decimal('amount_kwh', 12, 3);
            $table->enum('status', ['recorded'])->default('recorded');
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('energy_transfers');
    }
};
