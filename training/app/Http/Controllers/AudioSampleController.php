<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;

class AudioSampleController extends Controller
{
    private const ALLOWED_EXTENSIONS = ['wav', 'mp3', 'ogg', 'webm'];

    public function index(Request $request): View
    {
        $query = AudioSample::query();

        if ($request->filled('category') && $request->category !== 'all') {
            $query->where('category', $request->category);
        }
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('original_name', 'like', '%' . str_replace(['%', '_'], ['\%', '\_'], $search) . '%')
                  ->orWhere('label', 'like', '%' . str_replace(['%', '_'], ['\%', '\_'], $search) . '%')
                  ->orWhere('transcript', 'like', '%' . str_replace(['%', '_'], ['\%', '\_'], $search) . '%');
            });
        }

        $samples = $query->latest()->paginate(20);

        $stats = AudioSample::selectRaw("
            count(*) as total,
            sum(case when status = 'labeled' then 1 else 0 end) as labeled,
            sum(case when status = 'unlabeled' then 1 else 0 end) as unlabeled,
            sum(case when status = 'verified' then 1 else 0 end) as verified,
            round(coalesce(sum(duration), 0) / 3600.0, 1) as totalDuration
        ")->first();

        $stats = [
            'total' => $stats->total ?? 0,
            'labeled' => $stats->labeled ?? 0,
            'unlabeled' => $stats->unlabeled ?? 0,
            'verified' => $stats->verified ?? 0,
            'totalDuration' => $stats->totalDuration ?? 0,
        ];

        return view('dataset.index', compact('samples', 'stats'));
    }

    public function store(Request $request): JsonResponse|RedirectResponse
    {
        $validated = $request->validate([
            'audio' => 'required|file|mimes:wav,mp3,ogg,webm|max:51200',
            'category' => 'required|in:daily,protection,meditation,merit,sutra,general',
            'label' => 'nullable|string|max:500',
            'transcript' => 'nullable|string|max:10000',
            'duration' => 'nullable|numeric|min:0|max:7200',
            'sample_rate' => 'nullable|integer|in:8000,16000,22050,44100',
        ]);

        $file = $request->file('audio');
        $extension = strtolower($file->getClientOriginalExtension());
        if (!in_array($extension, self::ALLOWED_EXTENSIONS)) {
            $extension = 'wav';
        }

        $filename = Str::uuid() . '.' . $extension;
        $path = $file->storeAs('audio_samples', $filename, 'public');

        $sample = AudioSample::create([
            'filename' => $filename,
            'original_name' => $file->getClientOriginalName(),
            'file_path' => $path,
            'category' => $validated['category'],
            'label' => $validated['label'] ?? null,
            'transcript' => $validated['transcript'] ?? null,
            'duration' => $validated['duration'] ?? 0,
            'sample_rate' => $validated['sample_rate'] ?? 16000,
            'format' => $extension,
            'file_size' => $file->getSize(),
            'status' => !empty($validated['label']) ? 'labeled' : 'unlabeled',
            'device_info' => $request->userAgent(),
        ]);

        if ($request->wantsJson()) {
            return response()->json($sample, 201);
        }

        return redirect()->route('dataset.index')->with('success', 'อัปโหลดเสียงสำเร็จ');
    }

    public function show(AudioSample $audioSample): View
    {
        return view('dataset.show', compact('audioSample'));
    }

    public function update(Request $request, AudioSample $audioSample): JsonResponse|RedirectResponse
    {
        $validated = $request->validate([
            'label' => 'nullable|string|max:500',
            'transcript' => 'nullable|string|max:10000',
            'category' => 'nullable|in:daily,protection,meditation,merit,sutra,general',
            'status' => 'nullable|in:unlabeled,labeled,verified,rejected',
        ]);

        $audioSample->update(array_filter($validated, fn ($v) => $v !== null));

        if ($request->wantsJson()) {
            return response()->json($audioSample);
        }

        return redirect()->back()->with('success', 'อัปเดตข้อมูลสำเร็จ');
    }

    public function destroy(AudioSample $audioSample): JsonResponse|RedirectResponse
    {
        Storage::disk('public')->delete($audioSample->file_path);
        $audioSample->delete();

        if (request()->wantsJson()) {
            return response()->json(['message' => 'ลบสำเร็จ']);
        }

        return redirect()->route('dataset.index')->with('success', 'ลบข้อมูลสำเร็จ');
    }

    public function bulkAction(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'integer|exists:audio_samples,id',
            'action' => 'required|in:delete,verify,label',
        ]);

        $samples = AudioSample::whereIn('id', $validated['ids']);

        switch ($validated['action']) {
            case 'delete':
                foreach ($samples->get() as $sample) {
                    Storage::disk('public')->delete($sample->file_path);
                }
                $samples->delete();
                break;
            case 'verify':
                $samples->update(['status' => 'verified']);
                break;
            case 'label':
                $samples->update(['status' => 'labeled']);
                break;
        }

        return response()->json(['message' => 'ดำเนินการสำเร็จ']);
    }
}
