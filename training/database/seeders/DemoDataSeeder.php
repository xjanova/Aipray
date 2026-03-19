<?php

namespace Database\Seeders;

use App\Models\AudioSample;
use App\Models\TrainingJob;
use App\Models\AiModel;
use App\Models\Evaluation;
use Illuminate\Database\Seeder;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $categories = ['daily', 'protection', 'meditation', 'merit', 'sutra'];
        $chants = [
            'daily' => ['นะโม ตัสสะ', 'ไตรสรณคมน์', 'ศีล 5', 'อิติปิโส'],
            'protection' => ['รตนสูตร', 'ชัยมงคลคาถา', 'ยอดพระกัณฑ์ไตรปิฎก'],
            'meditation' => ['อานาปานสติ', 'พุทธานุสสติ'],
            'merit' => ['แผ่เมตตา', 'อุทิศส่วนกุศล'],
            'sutra' => ['กรณียเมตตสูตร', 'มงคลสูตร', 'ธัมมจักกัปปวัตตนสูตร'],
        ];

        // Create audio samples
        foreach ($categories as $cat) {
            $names = $chants[$cat];
            for ($i = 0; $i < rand(15, 30); $i++) {
                $name = $names[array_rand($names)];
                $statuses = ['unlabeled', 'labeled', 'verified'];
                $status = $statuses[array_rand($statuses)];
                AudioSample::create([
                    'filename' => fake()->uuid() . '.wav',
                    'original_name' => $name . '_' . ($i + 1) . '.wav',
                    'file_path' => 'audio_samples/demo_' . fake()->uuid() . '.wav',
                    'category' => $cat,
                    'label' => $name,
                    'transcript' => $name,
                    'duration' => rand(5, 120),
                    'sample_rate' => 16000,
                    'format' => 'wav',
                    'file_size' => rand(10000, 500000),
                    'status' => $status,
                    'device_info' => 'Demo Browser',
                    'created_at' => now()->subDays(rand(0, 30)),
                ]);
            }
        }

        // Create training jobs
        $models = ['whisper-tiny', 'whisper-base', 'whisper-small'];
        for ($j = 0; $j < 5; $j++) {
            $epochs = rand(5, 15);
            $currentEpoch = $j < 4 ? $epochs : rand(1, $epochs);
            $status = $j < 4 ? 'completed' : 'running';
            $accuracy = min(99, 60 + $j * 8 + rand(0, 5));

            $lossHistory = [];
            $metricsHistory = [];
            for ($e = 1; $e <= $currentEpoch; $e++) {
                $tl = 2.5 * exp(-0.3 * $e) + 0.1 + (rand(-100, 100) / 5000);
                $vl = $tl * 1.05;
                $wer = max(5, 80 * exp(-0.25 * $e));
                $cer = max(2, 40 * exp(-0.25 * $e));
                $lossHistory[] = ['epoch' => $e, 'train' => round($tl, 4), 'val' => round($vl, 4)];
                $metricsHistory[] = ['epoch' => $e, 'wer' => round($wer, 2), 'cer' => round($cer, 2), 'accuracy' => round($accuracy, 2)];
            }

            $job = TrainingJob::create([
                'name' => 'Training Run #' . ($j + 1),
                'base_model' => $models[array_rand($models)],
                'dataset_filter' => 'all',
                'learning_rate' => 0.0001,
                'batch_size' => 8,
                'epochs' => $epochs,
                'current_epoch' => $currentEpoch,
                'train_split' => 80,
                'optimizer' => 'adamw',
                'augmentation' => ['noise' => true, 'speed' => true, 'pitch' => false],
                'status' => $status,
                'training_loss' => round($lossHistory[count($lossHistory) - 1]['train'], 4),
                'validation_loss' => round($lossHistory[count($lossHistory) - 1]['val'], 4),
                'wer' => round($metricsHistory[count($metricsHistory) - 1]['wer'], 2),
                'cer' => round($metricsHistory[count($metricsHistory) - 1]['cer'], 2),
                'accuracy' => $accuracy,
                'loss_history' => $lossHistory,
                'metrics_history' => $metricsHistory,
                'log' => "=== Training Run #" . ($j + 1) . " ===\n",
                'started_at' => now()->subDays(rand(1, 20)),
                'completed_at' => $status === 'completed' ? now()->subDays(rand(0, 10)) : null,
            ]);

            if ($status === 'completed') {
                $model = AiModel::create([
                    'name' => 'Aipray-Thai-v' . ($j + 1),
                    'version' => '1.' . $j,
                    'base_model' => $job->base_model,
                    'training_job_id' => $job->id,
                    'accuracy' => $accuracy,
                    'wer' => $job->wer,
                    'cer' => $job->cer,
                    'total_samples_trained' => AudioSample::count(),
                    'total_hours_trained' => round(AudioSample::sum('duration') / 3600, 1),
                    'status' => $j === 3 ? 'deployed' : 'active',
                    'file_size' => rand(50, 500) * 1048576,
                    'created_at' => $job->completed_at,
                ]);

                // Create evaluations
                for ($ev = 0; $ev < rand(2, 5); $ev++) {
                    Evaluation::create([
                        'ai_model_id' => $model->id,
                        'eval_type' => ['live', 'batch', 'live'][rand(0, 2)],
                        'accuracy' => $accuracy - rand(0, 5),
                        'wer' => $job->wer + rand(0, 3),
                        'cer' => $job->cer + rand(0, 2),
                        'latency_ms' => rand(50, 300),
                        'recognized_text' => 'นะโม ตัสสะ ภะคะวะโต',
                        'reference_text' => 'นะโม ตัสสะ ภะคะวะโต',
                        'created_at' => now()->subDays(rand(0, 15)),
                    ]);
                }
            }
        }
    }
}
