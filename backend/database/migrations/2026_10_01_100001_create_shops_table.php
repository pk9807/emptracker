<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shops', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('owner_name')->nullable();
            $table->string('phone')->nullable();
            $table->string('address')->nullable();
            $table->double('latitude', 11, 8);
            $table->double('longitude', 11, 8);
            $table->integer('geofence_radius_meters')->default(100);
            $table->string('qr_code')->nullable()->unique();
            $table->string('category')->default('RETAIL'); // RETAIL, WHOLESALE, DISTRIBUTOR, SUPERMARKET, PHARMACY
            $table->string('status')->default('ACTIVE'); // ACTIVE, INACTIVE
            $table->string('photo_url')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shops');
    }
};
