<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ai_model_id')->constrained('ai_models')->cascadeOnDelete();
            $table->enum('eval_type', ['live', 'file', 'batch'])->default('live');
            $table->text('recognized_text')->nullable();
            $table->text('reference_text')->nullable();
            $table->float('accuracy')->nullable();
            $table->float('wer')->nullable();
            $table->float('cer')->nullable();
            $table->float('latency_ms')->nullable();
            $table->string('audio_file')->nullable();
            $table->json('details')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('evaluations');
    }
};
