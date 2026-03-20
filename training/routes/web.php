<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\AudioSampleController;
use App\Http\Controllers\RecordController;
use App\Http\Controllers\TrainingController;
use App\Http\Controllers\EvaluationController;
use App\Http\Controllers\AiModelController;

// Dashboard
Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

// Dataset Management
Route::get('/dataset', [AudioSampleController::class, 'index'])->name('dataset.index');
Route::post('/dataset', [AudioSampleController::class, 'store'])->name('dataset.store')->middleware('throttle:30,1');
Route::get('/dataset/{audioSample}', [AudioSampleController::class, 'show'])->name('dataset.show');
Route::put('/dataset/{audioSample}', [AudioSampleController::class, 'update'])->name('dataset.update');
Route::delete('/dataset/{audioSample}', [AudioSampleController::class, 'destroy'])->name('dataset.destroy');
Route::post('/dataset/bulk-action', [AudioSampleController::class, 'bulkAction'])->name('dataset.bulk');

// Recording — rate-limit uploads to prevent abuse
Route::get('/record', [RecordController::class, 'index'])->name('record.index');
Route::post('/record/store', [RecordController::class, 'storeRecording'])->name('record.store')->middleware('throttle:20,1');

// Training
Route::get('/training', [TrainingController::class, 'index'])->name('training.index');
Route::post('/training/start', [TrainingController::class, 'start'])->name('training.start')->middleware('throttle:5,1');
Route::post('/training/{trainingJob}/simulate', [TrainingController::class, 'simulateEpoch'])->name('training.simulate');
Route::get('/training/{trainingJob}/progress', [TrainingController::class, 'progress'])->name('training.progress');
Route::post('/training/{trainingJob}/stop', [TrainingController::class, 'stop'])->name('training.stop');
Route::post('/training/{trainingJob}/resume', [TrainingController::class, 'resume'])->name('training.resume');
Route::post('/training/{trainingJob}/cancel', [TrainingController::class, 'cancel'])->name('training.cancel');

// Evaluation
Route::get('/evaluate', [EvaluationController::class, 'index'])->name('evaluate.index');
Route::post('/evaluate', [EvaluationController::class, 'evaluate'])->name('evaluate.run')->middleware('throttle:30,1');
Route::post('/evaluate/batch', [EvaluationController::class, 'batchEvaluate'])->name('evaluate.batch')->middleware('throttle:10,1');

// Model Management
Route::get('/models', [AiModelController::class, 'index'])->name('models.index');
Route::get('/models/{aiModel}', [AiModelController::class, 'show'])->name('models.show');
Route::put('/models/{aiModel}', [AiModelController::class, 'update'])->name('models.update');
Route::delete('/models/{aiModel}', [AiModelController::class, 'destroy'])->name('models.destroy');
Route::post('/models/{aiModel}/deploy', [AiModelController::class, 'deploy'])->name('models.deploy');
