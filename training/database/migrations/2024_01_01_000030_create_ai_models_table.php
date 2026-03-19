<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_models', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('version')->default('1.0');
            $table->string('base_model');
            $table->foreignId('training_job_id')->nullable()->constrained('training_jobs')->nullOnDelete();
            $table->string('file_path')->nullable();
            $table->integer('file_size')->default(0);
            $table->float('accuracy')->nullable();
            $table->float('wer')->nullable();
            $table->float('cer')->nullable();
            $table->integer('total_samples_trained')->default(0);
            $table->float('total_hours_trained')->default(0);
            $table->json('eval_results')->nullable();
            $table->enum('status', ['active', 'archived', 'deploying', 'deployed'])->default('active');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_models');
    }
};
