<?php

namespace App\Http\Controllers;

use App\Models\TrainingJob;
use App\Models\AudioSample;
use App\Models\AiModel;
use Illuminate\Http\Request;

class TrainingController extends Controller
{
    public function index()
    {
        $jobs = TrainingJob::latest()->paginate(10);
        $sampleCount = AudioSample::count();
        $labeledCount = AudioSample::where('status', '!=', 'unlabeled')->count();
        return view('training.index', compact('jobs', 'sampleCount', 'labeledCount'));
    }

    public function start(Request $request)
    {
        $request->validate([
            'base_model' => 'required|string',
            'dataset_filter' => 'required|string',
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

        $job = TrainingJob::create([
            'name' => 'Training ' . now()->format('Y-m-d H:i'),
            'base_model' => $request->base_model,
            'dataset_filter' => $request->dataset_filter,
            'learning_rate' => $request->learning_rate,
            'batch_size' => $request->batch_size,
            'epochs' => $request->epochs,
            'train_split' => $request->train_split,
            'optimizer' => $request->optimizer,
            'augmentation' => $augmentation,
            'status' => 'running',
            'started_at' => now(),
            'loss_history' => [],
            'metrics_history' => [],
            'log' => "=== Training Started ===\nModel: {$request->base_model}\nDataset: {$request->dataset_filter}\nEpochs: {$request->epochs}\n",
        ]);

        return response()->json($job, 201);
    }

    public function progress(TrainingJob $trainingJob)
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

    public function simulateEpoch(TrainingJob $trainingJob)
    {
        if ($trainingJob->status !== 'running') {
            return response()->json(['error' => 'Job is not running'], 400);
        }

        $epoch = $trainingJob->current_epoch + 1;
        $totalEpochs = $trainingJob->epochs;

        // Simulate realistic training metrics
        $baseLoss = 2.5 * exp(-0.3 * $epoch) + 0.1 + (mt_rand(-100, 100) / 5000);
        $valLoss = $baseLoss * (1.05 + mt_rand(0, 200) / 5000);
        $wer = max(5, 80 * exp(-0.25 * $epoch) + mt_rand(-200, 200) / 100);
        $cer = max(2, 40 * exp(-0.25 * $epoch) + mt_rand(-100, 100) / 100);
        $accuracy = min(99, 100 - $wer * 0.8);

        $lossHistory = $trainingJob->loss_history ?? [];
        $lossHistory[] = ['epoch' => $epoch, 'train' => round($baseLoss, 4), 'val' => round($valLoss, 4)];

        $metricsHistory = $trainingJob->metrics_history ?? [];
        $metricsHistory[] = ['epoch' => $epoch, 'wer' => round($wer, 2), 'cer' => round($cer, 2), 'accuracy' => round($accuracy, 2)];

        $log = $trainingJob->log;
        $log .= sprintf(
            "\n[Epoch %d/%d] loss=%.4f val_loss=%.4f WER=%.2f%% CER=%.2f%% acc=%.2f%%",
            $epoch, $totalEpochs, $baseLoss, $valLoss, $wer, $cer, $accuracy
        );

        $isComplete = $epoch >= $totalEpochs;

        $trainingJob->update([
            'current_epoch' => $epoch,
            'training_loss' => round($baseLoss, 4),
            'validation_loss' => round($valLoss, 4),
            'wer' => round($wer, 2),
            'cer' => round($cer, 2),
            'accuracy' => round($accuracy, 2),
            'loss_history' => $lossHistory,
            'metrics_history' => $metricsHistory,
            'log' => $log,
            'status' => $isComplete ? 'completed' : 'running',
            'completed_at' => $isComplete ? now() : null,
        ]);

        if ($isComplete) {
            AiModel::create([
                'name' => "Aipray-{$trainingJob->base_model}-v" . AiModel::count() + 1,
                'version' => '1.' . AiModel::count(),
                'base_model' => $trainingJob->base_model,
                'training_job_id' => $trainingJob->id,
                'accuracy' => $trainingJob->accuracy,
                'wer' => $trainingJob->wer,
                'cer' => $trainingJob->cer,
                'total_samples_trained' => AudioSample::count(),
                'total_hours_trained' => round(AudioSample::sum('duration') / 3600, 1),
                'status' => 'active',
                'file_size' => mt_rand(50, 500) * 1048576,
            ]);
        }

        return response()->json($trainingJob->fresh());
    }

    public function stop(TrainingJob $trainingJob)
    {
        $trainingJob->update([
            'status' => 'paused',
            'log' => $trainingJob->log . "\n\n=== Training Paused ===",
        ]);

        return response()->json($trainingJob);
    }

    public function cancel(TrainingJob $trainingJob)
    {
        $trainingJob->update([
            'status' => 'cancelled',
            'completed_at' => now(),
            'log' => $trainingJob->log . "\n\n=== Training Cancelled ===",
        ]);

        return response()->json($trainingJob);
    }
}
