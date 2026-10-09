<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('location_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->double('latitude', 11, 8);
            $table->double('longitude', 11, 8);
            $table->double('speed', 8, 2)->default(0.0);
            $table->double('heading', 8, 2)->default(0.0);
            $table->double('accuracy', 8, 2)->default(10.0);
            $table->integer('battery_level')->default(100);
            $table->dateTime('recorded_at');
            $table->timestamps();

            $table->index(['user_id', 'recorded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('location_histories');
    }
};
