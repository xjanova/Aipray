<?php

namespace App\Http\Controllers;

use App\Models\AiModel;
use Illuminate\Http\Request;

class AiModelController extends Controller
{
    public function index(Request $request)
    {
        $query = AiModel::with('trainingJob');

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $models = $query->latest()->get();
        return view('models.index', compact('models'));
    }

    public function show(AiModel $aiModel)
    {
        $aiModel->load(['trainingJob', 'evaluations']);
        return view('models.show', compact('aiModel'));
    }

    public function update(Request $request, AiModel $aiModel)
    {
        $request->validate([
            'status' => 'nullable|in:active,archived,deploying,deployed',
            'notes' => 'nullable|string',
            'name' => 'nullable|string|max:255',
        ]);

        $aiModel->update($request->only(['status', 'notes', 'name']));

        if ($request->wantsJson()) {
            return response()->json($aiModel);
        }

        return redirect()->back()->with('success', 'อัปเดตโมเดลสำเร็จ');
    }

    public function destroy(AiModel $aiModel)
    {
        if ($aiModel->file_path) {
            \Storage::disk('public')->delete($aiModel->file_path);
        }
        $aiModel->delete();

        if (request()->wantsJson()) {
            return response()->json(['message' => 'ลบโมเดลสำเร็จ']);
        }

        return redirect()->route('models.index')->with('success', 'ลบโมเดลสำเร็จ');
    }

    public function deploy(AiModel $aiModel)
    {
        AiModel::where('status', 'deployed')->update(['status' => 'active']);
        $aiModel->update(['status' => 'deployed']);

        return response()->json(['message' => 'Deploy สำเร็จ', 'model' => $aiModel]);
    }
}
