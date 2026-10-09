<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->date('date');
            $table->dateTime('check_in_time');
            $table->dateTime('check_out_time')->nullable();
            $table->double('check_in_lat', 11, 8)->nullable();
            $table->double('check_in_lng', 11, 8)->nullable();
            $table->string('check_in_address')->nullable();
            $table->double('check_out_lat', 11, 8)->nullable();
            $table->double('check_out_lng', 11, 8)->nullable();
            $table->string('check_out_address')->nullable();
            $table->string('check_in_photo_url')->nullable();
            $table->string('check_out_photo_url')->nullable();
            $table->integer('battery_level')->nullable();
            $table->double('total_distance_km', 8, 2)->default(0.0);
            $table->string('status')->default('PRESENT'); // PRESENT, ON_DUTY, HALF_DAY, COMPLETED
            $table->timestamps();

            $table->index(['user_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
