<?php

namespace App\Http\Controllers;

use App\Models\TrainingJob;
use App\Models\AudioSample;
use App\Models\AiModel;
use App\Services\MlServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;

class TrainingController extends Controller
{
    public function __construct(
        private readonly MlServiceClient $mlService,
    ) {}

    public function index(): View
    {
        $jobs = TrainingJob::latest()->paginate(10);
        $sampleCount = AudioSample::count();
        $labeledCount = AudioSample::where('status', '!=', 'unlabeled')->count();
        $mlHealthy = $this->mlService->isHealthy();
        $mlHealth = $this->mlService->health();
        return view('training.index', compact('jobs', 'sampleCount', 'labeledCount', 'mlHealthy', 'mlHealth'));
    }

    public function start(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'base_model' => 'required|in:whisper-tiny,whisper-base,whisper-small,whisper-medium',
            'dataset_filter' => 'required|in:all,labeled,verified',
            'learning_rate' => 'required|numeric|min:0.000001|max:0.1',
            'batch_size' => 'required|integer|in:4,8,16,32',
            'epochs' => 'required|integer|min:1|max:100',
            'train_split' => 'required|integer|min:50|max:95',
            'optimizer' => 'required|in:adamw,adam,sgd',
        ]);

        $augmentation = [
            'noise' => $request->boolean('aug_noise'),
            'speed' => $request->boolean('aug_speed'),
            'pitch' => $request->boolean('aug_pitch'),
        ];

        // Get audio samples for training
        $samplesQuery = AudioSample::query();
        if ($validated['dataset_filter'] === 'labeled') {
            $samplesQuery->whereIn('status', ['labeled', 'verified']);
        } elseif ($validated['dataset_filter'] === 'verified') {
            $samplesQuery->where('status', 'verified');
        }

        $samples = $samplesQuery->get()->map(fn ($s) => [
            'id' => $s->id,
            'filename' => $s->filename,
            'file_path' => storage_path('app/public/' . $s->file_path),
            'category' => $s->category,
            'label' => $s->label,
            'transcript' => $s->transcript,
            'duration' => $s->duration,
        ])->toArray();

        if (empty($samples)) {
            return response()->json(['error' => 'No audio samples available for training'], 422);
        }

        // Create training job record
        $job = TrainingJob::create([
            'name' => 'Training ' . now()->format('Y-m-d H:i'),
            'base_model' => $validated['base_model'],
            'dataset_filter' => $validated['dataset_filter'],
            'learning_rate' => $validated['learning_rate'],
            'batch_size' => $validated['batch_size'],
            'epochs' => $validated['epochs'],
            'train_split' => $validated['train_split'],
            'optimizer' => $validated['optimizer'],
            'augmentation' => $augmentation,
            'status' => 'starting',
            'started_at' => now(),
            'loss_history' => [],
            'metrics_history' => [],
            'log' => "=== Connecting to ML Service ===\n",
        ]);

        // Send training request to ML service
        try {
            $this->mlService->startTraining([
                'job_id' => $job->id,
                'base_model' => $validated['base_model'],
                'learning_rate' => $validated['learning_rate'],
                'batch_size' => $validated['batch_size'],
                'epochs' => $validated['epochs'],
                'optimizer' => $validated['optimizer'],
                'train_split' => $validated['train_split'] / 100,
                'augmentation' => $augmentation,
                'samples' => $samples,
            ]);

            $job->update([
                'status' => 'running',
                'log' => $job->log . "ML Service connected. Training started.\n",
            ]);
        } catch (\Exception $e) {
            Log::error("ML training start failed: " . $e->getMessage());
            $job->update([
                'status' => 'failed',
                'log' => $job->log . "Failed to connect to ML Service: " . $e->getMessage() . "\n",
                'completed_at' => now(),
            ]);

            return response()->json([
                'error' => 'Failed to start ML training. Is the ML service running?',
                'details' => $e->getMessage(),
                'job' => $job,
            ], 503);
        }

        return response()->json($job, 201);
    }

    /**
     * Receive training progress callback from ML service.
     */
    public function mlCallback(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'job_id' => 'required|integer|exists:training_jobs,id',
            'status' => 'nullable|string',
            'current_epoch' => 'nullable|integer',
            'training_loss' => 'nullable|numeric',
            'validation_loss' => 'nullable|numeric',
            'wer' => 'nullable|numeric',
            'cer' => 'nullable|numeric',
            'accuracy' => 'nullable|numeric',
            'loss_history' => 'nullable|array',
            'metrics_history' => 'nullable|array',
            'log' => 'nullable|string',
            'model_path' => 'nullable|string',
            'elapsed' => 'nullable|integer',
        ]);

        $job = TrainingJob::findOrFail($validated['job_id']);

        $updateData = array_filter([
            'status' => $validated['status'] ?? null,
            'current_epoch' => $validated['current_epoch'] ?? null,
            'training_loss' => $validated['training_loss'] ?? null,
            'validation_loss' => $validated['validation_loss'] ?? null,
            'wer' => $validated['wer'] ?? null,
            'cer' => $validated['cer'] ?? null,
            'accuracy' => $validated['accuracy'] ?? null,
            'loss_history' => $validated['loss_history'] ?? null,
            'metrics_history' => $validated['metrics_history'] ?? null,
            'log' => $validated['log'] ?? null,
            'elapsed' => $validated['elapsed'] ?? null,
        ], fn ($v) => $v !== null);

        if (in_array($validated['status'] ?? '', ['completed', 'failed', 'cancelled'])) {
            $updateData['completed_at'] = now();
        }

        DB::transaction(function () use ($job, $updateData, $validated) {
            $job->update($updateData);

            // Create AI Model record when training completes
            if (($validated['status'] ?? '') === 'completed') {
                // Use max(id) + 1 inside transaction to avoid race condition on version naming
                $maxId = AiModel::lockForUpdate()->max('id') ?? 0;
                $modelVersion = $maxId + 1;
                AiModel::create([
                    'name' => "Aipray-{$job->base_model}-v{$modelVersion}",
                    'version' => '1.' . $modelVersion,
                    'base_model' => $job->base_model,
                    'training_job_id' => $job->id,
                    'accuracy' => $job->accuracy,
                    'wer' => $job->wer,
                    'cer' => $job->cer,
                    'total_samples_trained' => AudioSample::count(),
                    'total_hours_trained' => round(AudioSample::sum('duration') / 3600, 1),
                    'status' => 'active',
                    'file_path' => $validated['model_path'] ?? null,
                    'file_size' => 0,
                ]);
            }
        });

        return response()->json(['message' => 'Callback received']);
    }

    public function progress(TrainingJob $trainingJob): JsonResponse
    {
        return response()->json([
            'id' => $trainingJob->id,
            'status' => $trainingJob->status,
            'current_epoch' => $trainingJob->current_epoch,
            'epochs' => $trainingJob->epochs,
            'progress' => $trainingJob->progress,
            'training_loss' => $trainingJob->training_loss,
            'validation_loss' => $trainingJob->validation_loss,
            'wer' => $trainingJob->wer,
            'cer' => $trainingJob->cer,
            'accuracy' => $trainingJob->accuracy,
            'loss_history' => $trainingJob->loss_history,
            'metrics_history' => $trainingJob->metrics_history,
            'elapsed' => $trainingJob->elapsed,
            'log' => $trainingJob->log,
        ]);
    }

    public function stop(TrainingJob $trainingJob): JsonResponse
    {
        if ($trainingJob->status !== 'running') {
            return response()->json(['error' => 'Job is not running'], 400);
        }

        try {
            $this->mlService->pauseTraining($trainingJob->id);
        } catch (\Exception $e) {
            Log::warning("Failed to pause ML training: " . $e->getMessage());
        }

        $trainingJob->update([
            'status' => 'paused',
            'log' => $trainingJob->log . "\n\n=== Training Paused ===",
        ]);

        return response()->json($trainingJob);
    }

    public function resume(TrainingJob $trainingJob): JsonResponse
    {
        if ($trainingJob->status !== 'paused') {
            return response()->json(['error' => 'Job is not paused'], 400);
        }

        $trainingJob->update([
            'status' => 'running',
            'log' => $trainingJob->log . "\n\n=== Training Resumed ===",
        ]);

        return response()->json($trainingJob);
    }

    public function cancel(TrainingJob $trainingJob): JsonResponse
    {
        if (in_array($trainingJob->status, ['completed', 'cancelled'])) {
            return response()->json(['error' => 'Job is already finished'], 400);
        }

        try {
            $this->mlService->cancelTraining($trainingJob->id);
        } catch (\Exception $e) {
            Log::warning("Failed to cancel ML training: " . $e->getMessage());
        }

        $trainingJob->update([
            'status' => 'cancelled',
            'completed_at' => now(),
            'log' => $trainingJob->log . "\n\n=== Training Cancelled ===",
        ]);

        return response()->json($trainingJob);
    }
}
