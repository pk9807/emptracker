<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('ai_audit_logs')) {
            Schema::create('ai_audit_logs', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->index();
                $table->string('user_role')->default('employee');
                $table->string('source')->default('local_ai');
                $table->string('response_type')->default('answer');
                $table->json('tools_used')->nullable();
                $table->boolean('requires_confirmation')->default(false);
                $table->string('action')->nullable();
                $table->double('latency_ms')->default(0);
                $table->timestamp('created_at')->useCurrent();

                $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            });
        }

        if (!Schema::hasTable('ai_conversations')) {
            Schema::create('ai_conversations', function (Blueprint $table) {
                $table->id();
                $table->string('session_id')->unique();
                $table->unsignedBigInteger('user_id')->index();
                $table->string('title')->nullable();
                $table->timestamps();

                $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            });
        }

        if (!Schema::hasTable('ai_messages')) {
            Schema::create('ai_messages', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('conversation_id')->index();
                $table->enum('role', ['user', 'assistant', 'system', 'tool'])->default('user');
                $table->text('content');
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->foreign('conversation_id')->references('id')->on('ai_conversations')->onDelete('cascade');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ai_messages');
        Schema::dropIfExists('ai_conversations');
        Schema::dropIfExists('ai_audit_logs');
    }
};
