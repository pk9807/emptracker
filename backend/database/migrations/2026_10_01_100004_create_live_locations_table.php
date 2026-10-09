<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('live_locations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->double('latitude', 11, 8);
            $table->double('longitude', 11, 8);
            $table->double('accuracy', 8, 2)->default(10.0);
            $table->double('speed', 8, 2)->default(0.0); // in m/s or km/h
            $table->double('heading', 8, 2)->default(0.0); // bearing in degrees 0-360
            $table->double('altitude', 8, 2)->default(0.0);
            $table->integer('battery_level')->default(100);
            $table->boolean('is_mocked')->default(false);
            $table->string('activity_type')->default('STILL'); // STILL, WALKING, ON_BICYCLE, IN_VEHICLE
            $table->boolean('is_online')->default(true);
            $table->dateTime('last_ping_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('live_locations');
    }
};
