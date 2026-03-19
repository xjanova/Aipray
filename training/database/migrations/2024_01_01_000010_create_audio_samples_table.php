<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audio_samples', function (Blueprint $table) {
            $table->id();
            $table->string('filename');
            $table->string('original_name');
            $table->string('file_path');
            $table->string('category')->default('general');
            $table->string('label')->nullable();
            $table->text('transcript')->nullable();
            $table->float('duration')->default(0);
            $table->integer('sample_rate')->default(16000);
            $table->string('format')->default('wav');
            $table->integer('file_size')->default(0);
            $table->enum('status', ['unlabeled', 'labeled', 'verified', 'rejected'])->default('unlabeled');
            $table->string('device_info')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audio_samples');
    }
};
