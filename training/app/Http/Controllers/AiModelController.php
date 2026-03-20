<?php

namespace App\Http\Controllers;

use App\Models\AiModel;
use App\Services\MlServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class AiModelController extends Controller
{
    public function __construct(
        private readonly MlServiceClient $mlService,
    ) {}

    public function index(Request $request): View
    {
        $query = AiModel::with('trainingJob');

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $models = $query->latest()->get();
        $mlModels = $this->mlService->getModels();
        return view('models.index', compact('models', 'mlModels'));
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

        // Load model on ML service
        if ($aiModel->file_path && $this->mlService->isHealthy()) {
            try {
                $this->mlService->loadModel($aiModel->file_path, $aiModel->name);
            } catch (\Exception $e) {
                Log::warning("Failed to load model on ML service: " . $e->getMessage());
            }
        }

        return response()->json(['message' => 'Deploy สำเร็จ', 'model' => $aiModel->fresh()]);
    }

    /**
     * Export model to ONNX format for mobile/edge deployment.
     */
    public function exportOnnx(AiModel $aiModel): JsonResponse
    {
        if (!$aiModel->file_path) {
            return response()->json(['error' => 'ไม่มีไฟล์โมเดล'], 400);
        }

        if (!$this->mlService->isHealthy()) {
            return response()->json(['error' => 'ML Service ไม่ทำงาน'], 503);
        }

        try {
            $result = $this->mlService->exportOnnx($aiModel->file_path);
            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json(['error' => 'ONNX export failed: ' . $e->getMessage()], 500);
        }
    }
}
