<?php

namespace App\Http\Controllers;

use App\Models\AiModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class AiModelController extends Controller
{
    public function index(Request $request): View
    {
        $query = AiModel::with('trainingJob');

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $models = $query->latest()->get();
        return view('models.index', compact('models'));
    }

    public function show(AiModel $aiModel): View
    {
        $aiModel->load(['trainingJob', 'evaluations']);
        return view('models.show', compact('aiModel'));
    }

    public function update(Request $request, AiModel $aiModel): JsonResponse|RedirectResponse
    {
        $validated = $request->validate([
            'status' => 'nullable|in:active,archived,deploying,deployed',
            'notes' => 'nullable|string|max:5000',
            'name' => 'nullable|string|max:255',
        ]);

        $aiModel->update(array_filter($validated, fn ($v) => $v !== null));

        if ($request->wantsJson()) {
            return response()->json($aiModel);
        }

        return redirect()->back()->with('success', 'อัปเดตโมเดลสำเร็จ');
    }

    public function destroy(AiModel $aiModel): JsonResponse|RedirectResponse
    {
        if ($aiModel->file_path) {
            Storage::disk('public')->delete($aiModel->file_path);
        }
        $aiModel->delete();

        if (request()->wantsJson()) {
            return response()->json(['message' => 'ลบโมเดลสำเร็จ']);
        }

        return redirect()->route('models.index')->with('success', 'ลบโมเดลสำเร็จ');
    }

    public function deploy(AiModel $aiModel): JsonResponse
    {
        DB::transaction(function () use ($aiModel) {
            AiModel::where('status', 'deployed')->update(['status' => 'active']);
            $aiModel->update(['status' => 'deployed']);
        });

        return response()->json(['message' => 'Deploy สำเร็จ', 'model' => $aiModel->fresh()]);
    }
}
