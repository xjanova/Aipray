<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('audio_samples', function (Blueprint $table) {
            $table->index('category');
            $table->index('status');
            $table->index(['category', 'status']);
            $table->index('created_at');
        });

        Schema::table('training_jobs', function (Blueprint $table) {
            $table->index('status');
            $table->index('completed_at');
        });

        Schema::table('ai_models', function (Blueprint $table) {
            $table->index('status');
        });

        Schema::table('evaluations', function (Blueprint $table) {
            $table->index(['ai_model_id', 'eval_type']);
        });
    }

    public function down(): void
    {
        Schema::table('audio_samples', function (Blueprint $table) {
            $table->dropIndex(['category']);
            $table->dropIndex(['status']);
            $table->dropIndex(['category', 'status']);
            $table->dropIndex(['created_at']);
        });

        Schema::table('training_jobs', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropIndex(['completed_at']);
        });

        Schema::table('ai_models', function (Blueprint $table) {
            $table->dropIndex(['status']);
        });

        Schema::table('evaluations', function (Blueprint $table) {
            $table->dropIndex(['ai_model_id', 'eval_type']);
        });
    }
};
