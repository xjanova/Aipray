<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use App\Models\TrainingJob;
use App\Models\AiModel;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        // Single aggregate query instead of 4 separate ones
        $sampleStats = AudioSample::selectRaw('count(*) as total, coalesce(sum(duration), 0) as total_duration')->first();
        $totalSamples = $sampleStats->total;
        $totalHours = round($sampleStats->total_duration / 3600, 1);

        $modelStats = AiModel::selectRaw('count(*) as total, max(accuracy) as best_accuracy')->first();
        $modelsCount = $modelStats->total;
        $bestAccuracy = $modelStats->best_accuracy ?? 0;

        $recentJobs = TrainingJob::latest()->take(5)->get();
        $recentSamples = AudioSample::latest()->take(10)->get();

        // Category distribution
        $categories = AudioSample::selectRaw('category, count(*) as count, sum(duration) as total_duration')
            ->groupBy('category')
            ->get();

        // Training accuracy history
        $accuracyHistory = TrainingJob::where('status', 'completed')
            ->orderBy('completed_at')
            ->take(30)
            ->get(['accuracy', 'completed_at', 'name']);

        return view('dashboard', compact(
            'totalSamples', 'totalHours', 'modelsCount', 'bestAccuracy',
            'recentJobs', 'recentSamples', 'categories', 'accuracyHistory'
        ));
    }
}
