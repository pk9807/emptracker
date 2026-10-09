<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('visits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->dateTime('check_in_time');
            $table->dateTime('check_out_time')->nullable();
            $table->double('check_in_lat', 11, 8);
            $table->double('check_in_lng', 11, 8);
            $table->double('check_out_lat', 11, 8)->nullable();
            $table->double('check_out_lng', 11, 8)->nullable();
            $table->string('photo_url')->nullable();
            $table->string('signature_url')->nullable();
            $table->text('notes')->nullable();
            $table->string('purpose')->default('ROUTINE_VISIT'); // ROUTINE_VISIT, ORDER_COLLECTION, PAYMENT_RECOVERY, NEW_CLIENT_ONBOARDING, ISSUE_RESOLUTION
            $table->string('outcome')->nullable(); // ORDER_PLACED, PAYMENT_RECEIVED, FOLLOW_UP_REQUIRED, SHOP_CLOSED, REJECTED
            $table->decimal('order_amount', 12, 2)->default(0.00);
            $table->boolean('is_verified_geofence')->default(false);
            $table->double('distance_from_shop_meters', 8, 2)->default(0.0);
            $table->string('status')->default('STARTED'); // STARTED, COMPLETED, CANCELLED
            $table->timestamps();

            $table->index(['user_id', 'shop_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('visits');
    }
};
