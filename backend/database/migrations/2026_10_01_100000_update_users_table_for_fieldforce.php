<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('employee')->after('email'); // admin, employee, manager
            $table->string('phone')->nullable()->after('role');
            $table->string('employee_code')->nullable()->unique()->after('phone');
            $table->string('designation')->nullable()->after('employee_code');
            $table->string('department')->nullable()->after('designation');
            $table->string('avatar')->nullable()->after('department');
            $table->boolean('is_active')->default(true)->after('avatar');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'role',
                'phone',
                'employee_code',
                'designation',
                'department',
                'avatar',
                'is_active',
            ]);
        });
    }
};
