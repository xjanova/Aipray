<?php

namespace App\Http\Controllers;

use App\Models\AiModel;
use App\Models\AudioSample;
use App\Models\Evaluation;
use App\Services\MlServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;

class EvaluationController extends Controller
{
    public function __construct(
        private readonly MlServiceClient $mlService,
    ) {}

    public function index(): View
    {
        $models = AiModel::where('status', '!=', 'archived')->latest()->get();
        $recentEvals = Evaluation::with('aiModel')->latest()->take(20)->get();
        $mlHealthy = $this->mlService->isHealthy();
        return view('evaluate.index', compact('models', 'recentEvals', 'mlHealthy'));
    }

    public function evaluate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'model_id' => 'required|exists:ai_models,id',
            'eval_type' => 'required|in:live,file,text',
            'audio' => 'nullable|file|mimes:wav,mp3,ogg,webm|max:51200',
            'recognized_text' => 'nullable|string|max:10000',
            'reference_text' => 'nullable|string|max:10000',
        ]);

        $aiModel = AiModel::findOrFail($validated['model_id']);
        $recognized = $validated['recognized_text'] ?? '';
        $reference = $validated['reference_text'] ?? '';
        $latencyMs = 0;

        // If audio file provided, try real transcription via ML service
        if ($request->hasFile('audio') && $this->mlService->isHealthy()) {
            try {
                $result = $this->mlService->evaluate(
                    $request->file('audio'),
                    $reference,
                    $aiModel->name,
                );

                $eval = Evaluation::create([
                    'ai_model_id' => $aiModel->id,
                    'eval_type' => $validated['eval_type'],
                    'recognized_text' => $result['recognized_text'] ?? '',
                    'reference_text' => $reference,
                    'accuracy' => $result['accuracy'] ?? 0,
                    'wer' => $result['wer'] ?? 100,
                    'cer' => $result['cer'] ?? 100,
                    'latency_ms' => $result['latency_ms'] ?? 0,
                ]);

                return response()->json($eval);
            } catch (\Exception $e) {
                Log::warning("ML evaluation failed, falling back to text comparison: " . $e->getMessage());
            }
        }

        // Fallback: text-based WER/CER calculation
        $wer = $this->calculateWER($reference, $recognized);
        $cer = $this->calculateCER($reference, $recognized);
        $accuracy = max(0, 100 - $wer);

        $eval = Evaluation::create([
            'ai_model_id' => $aiModel->id,
            'eval_type' => $validated['eval_type'],
            'recognized_text' => $recognized,
            'reference_text' => $reference,
            'accuracy' => round($accuracy, 2),
            'wer' => round($wer, 2),
            'cer' => round($cer, 2),
            'latency_ms' => $latencyMs,
        ]);

        return response()->json($eval);
    }

    public function batchEvaluate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'model_id' => 'required|exists:ai_models,id',
        ]);

        $aiModel = AiModel::findOrFail($validated['model_id']);
        $categories = ['daily', 'protection', 'meditation', 'merit', 'sutra'];
        $results = [];
        $totalWer = 0;
        $totalCer = 0;
        $totalSamples = 0;

        foreach ($categories as $cat) {
            $samples = AudioSample::where('category', $cat)
                ->whereNotNull('transcript')
                ->where('transcript', '!=', '')
                ->get();

            if ($samples->isEmpty()) {
                continue;
            }

            $catWer = 0;
            $catCer = 0;
            $catCount = 0;

            // Try real evaluation via ML service for each sample
            $useML = $this->mlService->isHealthy();

            foreach ($samples as $sample) {
                if ($useML && $sample->file_path) {
                    try {
                        $filePath = storage_path('app/public/' . $sample->file_path);
                        $mlResult = $this->mlService->transcribeFile($filePath, $aiModel->name);
                        $recognized = $mlResult['text'] ?? '';
                        $reference = $sample->transcript;
                        $wer = $this->calculateWER($reference, $recognized);
                        $cer = $this->calculateCER($reference, $recognized);
                    } catch (\Exception $e) {
                        Log::warning("ML transcription failed for sample {$sample->id}: " . $e->getMessage());
                        $useML = false;
                        $wer = $this->calculateWER($sample->transcript, $sample->label ?? '');
                        $cer = $this->calculateCER($sample->transcript, $sample->label ?? '');
                    }
                } else {
                    $wer = $this->calculateWER($sample->transcript, $sample->label ?? '');
                    $cer = $this->calculateCER($sample->transcript, $sample->label ?? '');
                }

                $catWer += $wer;
                $catCer += $cer;
                $catCount++;
            }

            if ($catCount > 0) {
                $avgWer = $catWer / $catCount;
                $avgCer = $catCer / $catCount;
                $results[] = [
                    'category' => $cat,
                    'samples' => $catCount,
                    'wer' => round($avgWer, 2),
                    'cer' => round($avgCer, 2),
                    'accuracy' => round(max(0, 100 - $avgWer), 2),
                ];
                $totalWer += $avgWer;
                $totalCer += $avgCer;
                $totalSamples++;
            }
        }

        $avgWer = $totalSamples > 0 ? $totalWer / $totalSamples : 100;
        $avgCer = $totalSamples > 0 ? $totalCer / $totalSamples : 100;

        Evaluation::create([
            'ai_model_id' => $aiModel->id,
            'eval_type' => 'batch',
            'accuracy' => round(max(0, 100 - $avgWer), 2),
            'wer' => round($avgWer, 2),
            'cer' => round($avgCer, 2),
            'latency_ms' => 0,
            'details' => $results,
        ]);

        return response()->json([
            'categories' => $results,
            'average_wer' => round($avgWer, 2),
            'average_cer' => round($avgCer, 2),
            'average_accuracy' => round(max(0, 100 - $avgWer), 2),
        ]);
    }

    /**
     * Live transcription endpoint - transcribes uploaded audio in real-time.
     */
    public function liveTranscribe(Request $request): JsonResponse
    {
        $request->validate([
            'audio' => 'required|file|mimes:wav,mp3,ogg,webm|max:51200',
            'model_id' => 'nullable|exists:ai_models,id',
        ]);

        if (!$this->mlService->isHealthy()) {
            return response()->json(['error' => 'ML service is not available'], 503);
        }

        try {
            $modelId = 'default';
            if ($request->filled('model_id')) {
                $modelId = AiModel::findOrFail($request->model_id)->name;
            }

            $result = $this->mlService->transcribeUpload($request->file('audio'), $modelId);
            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Transcription failed: ' . $e->getMessage()], 500);
        }
    }

    private function calculateWER(string $reference, string $recognized): float
    {
        if (empty($reference)) return 100;
        $refWords = preg_split('/\s+/u', trim($reference));
        $recWords = preg_split('/\s+/u', trim($recognized));
        if (empty($refWords)) return 100;

        $distance = $this->levenshteinArray($refWords, $recWords);
        return min(100, ($distance / count($refWords)) * 100);
    }

    private function calculateCER(string $reference, string $recognized): float
    {
        if (empty($reference)) return 100;
        $ref = mb_str_split(preg_replace('/\s+/u', '', $reference));
        $rec = mb_str_split(preg_replace('/\s+/u', '', $recognized));
        if (empty($ref)) return 100;

        $distance = $this->levenshteinArray($ref, $rec);
        return min(100, ($distance / count($ref)) * 100);
    }

    private function levenshteinArray(array $s, array $t): int
    {
        $n = count($s);
        $m = count($t);

        // Use two-row approach: O(min(n,m)) memory instead of O(n*m)
        if ($n < $m) {
            [$s, $t] = [$t, $s];
            [$n, $m] = [$m, $n];
        }

        $prev = range(0, $m);
        $curr = [];

        for ($i = 1; $i <= $n; $i++) {
            $curr[0] = $i;
            for ($j = 1; $j <= $m; $j++) {
                $cost = ($s[$i - 1] === $t[$j - 1]) ? 0 : 1;
                $curr[$j] = min(
                    $prev[$j] + 1,
                    $curr[$j - 1] + 1,
                    $prev[$j - 1] + $cost
                );
            }
            $prev = $curr;
        }

        return $prev[$m];
    }
}
