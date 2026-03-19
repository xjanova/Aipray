<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('base_model')->default('whisper-base');
            $table->string('dataset_filter')->default('all');
            $table->float('learning_rate')->default(0.0001);
            $table->integer('batch_size')->default(8);
            $table->integer('epochs')->default(10);
            $table->integer('current_epoch')->default(0);
            $table->integer('train_split')->default(80);
            $table->string('optimizer')->default('adamw');
            $table->json('augmentation')->nullable();
            $table->enum('status', ['pending', 'running', 'paused', 'completed', 'failed', 'cancelled'])->default('pending');
            $table->float('training_loss')->nullable();
            $table->float('validation_loss')->nullable();
            $table->float('wer')->nullable();
            $table->float('cer')->nullable();
            $table->float('accuracy')->nullable();
            $table->json('loss_history')->nullable();
            $table->json('metrics_history')->nullable();
            $table->text('log')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('training_jobs');
    }
};
