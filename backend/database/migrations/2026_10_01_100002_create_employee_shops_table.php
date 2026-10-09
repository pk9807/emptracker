<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employee_shops', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('shop_id')->constrained('shops')->cascadeOnDelete();
            $table->date('assigned_date')->nullable();
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'shop_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_shops');
    }
};
