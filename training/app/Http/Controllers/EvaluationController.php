<?php

namespace App\Http\Controllers;

use App\Models\AiModel;
use App\Models\Evaluation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class EvaluationController extends Controller
{
    public function index(): View
    {
        $models = AiModel::where('status', '!=', 'archived')->latest()->get();
        $recentEvals = Evaluation::with('aiModel')->latest()->take(20)->get();
        return view('evaluate.index', compact('models', 'recentEvals'));
    }

    public function evaluate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'model_id' => 'required|exists:ai_models,id',
            'eval_type' => 'required|in:live,file,batch',
            'recognized_text' => 'nullable|string|max:10000',
            'reference_text' => 'nullable|string|max:10000',
        ]);

        $recognized = $validated['recognized_text'] ?? '';
        $reference = $validated['reference_text'] ?? '';

        $wer = $this->calculateWER($reference, $recognized);
        $cer = $this->calculateCER($reference, $recognized);
        $accuracy = max(0, 100 - $wer);

        $eval = Evaluation::create([
            'ai_model_id' => $validated['model_id'],
            'eval_type' => $validated['eval_type'],
            'recognized_text' => $recognized,
            'reference_text' => $reference,
            'accuracy' => round($accuracy, 2),
            'wer' => round($wer, 2),
            'cer' => round($cer, 2),
            'latency_ms' => mt_rand(50, 500),
        ]);

        return response()->json($eval);
    }

    public function batchEvaluate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'model_id' => 'required|exists:ai_models,id',
        ]);

        // Simulate batch evaluation results
        $categories = ['daily', 'protection', 'meditation', 'merit', 'sutra'];
        $results = [];
        $totalWer = 0;
        $totalCer = 0;

        foreach ($categories as $cat) {
            $wer = mt_rand(500, 3000) / 100;
            $cer = mt_rand(200, 1500) / 100;
            $results[] = [
                'category' => $cat,
                'samples' => mt_rand(10, 100),
                'wer' => round($wer, 2),
                'cer' => round($cer, 2),
                'accuracy' => round(max(0, 100 - $wer), 2),
            ];
            $totalWer += $wer;
            $totalCer += $cer;
        }

        $avgWer = $totalWer / count($categories);
        $avgCer = $totalCer / count($categories);

        Evaluation::create([
            'ai_model_id' => $validated['model_id'],
            'eval_type' => 'batch',
            'accuracy' => round(max(0, 100 - $avgWer), 2),
            'wer' => round($avgWer, 2),
            'cer' => round($avgCer, 2),
            'latency_ms' => mt_rand(1000, 5000),
            'details' => $results,
        ]);

        return response()->json([
            'categories' => $results,
            'average_wer' => round($avgWer, 2),
            'average_cer' => round($avgCer, 2),
            'average_accuracy' => round(max(0, 100 - $avgWer), 2),
        ]);
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
        $d = [];

        for ($i = 0; $i <= $n; $i++) $d[$i][0] = $i;
        for ($j = 0; $j <= $m; $j++) $d[0][$j] = $j;

        for ($i = 1; $i <= $n; $i++) {
            for ($j = 1; $j <= $m; $j++) {
                $cost = ($s[$i - 1] === $t[$j - 1]) ? 0 : 1;
                $d[$i][$j] = min(
                    $d[$i - 1][$j] + 1,
                    $d[$i][$j - 1] + 1,
                    $d[$i - 1][$j - 1] + $cost
                );
            }
        }

        return $d[$n][$m];
    }
}
