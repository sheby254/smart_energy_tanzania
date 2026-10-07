<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meters', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 80);
            $table->string('number', 40);
            $table->enum('kind', ['home', 'business']);
            $table->decimal('balance_kwh', 12, 3)->default(0);
            $table->enum('status', ['pending', 'connected', 'disconnected'])
                ->default('pending');
            $table->timestamp('last_updated_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'number']);
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meters');
    }
};
