<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use App\Models\TrainingJob;
use App\Models\AiModel;
use App\Models\Evaluation;

class DashboardController extends Controller
{
    public function index()
    {
        $totalSamples = AudioSample::count();
        $totalDuration = AudioSample::sum('duration');
        $totalHours = round($totalDuration / 3600, 1);
        $modelsCount = AiModel::count();
        $bestAccuracy = AiModel::max('accuracy') ?? 0;

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
