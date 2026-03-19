<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AudioSampleController extends Controller
{
    public function index(Request $request)
    {
        $query = AudioSample::query();

        if ($request->filled('category') && $request->category !== 'all') {
            $query->where('category', $request->category);
        }
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('original_name', 'like', "%{$request->search}%")
                  ->orWhere('label', 'like', "%{$request->search}%")
                  ->orWhere('transcript', 'like', "%{$request->search}%");
            });
        }

        $samples = $query->latest()->paginate(20);

        $stats = [
            'total' => AudioSample::count(),
            'labeled' => AudioSample::where('status', 'labeled')->count(),
            'unlabeled' => AudioSample::where('status', 'unlabeled')->count(),
            'verified' => AudioSample::where('status', 'verified')->count(),
            'totalDuration' => round(AudioSample::sum('duration') / 3600, 1),
        ];

        return view('dataset.index', compact('samples', 'stats'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'audio' => 'required|file|mimes:wav,mp3,ogg,webm|max:51200',
            'category' => 'required|string',
            'label' => 'nullable|string|max:500',
            'transcript' => 'nullable|string',
        ]);

        $file = $request->file('audio');
        $filename = Str::uuid() . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs('audio_samples', $filename, 'public');

        $sample = AudioSample::create([
            'filename' => $filename,
            'original_name' => $file->getClientOriginalName(),
            'file_path' => $path,
            'category' => $request->category,
            'label' => $request->label,
            'transcript' => $request->transcript,
            'duration' => $request->input('duration', 0),
            'sample_rate' => $request->input('sample_rate', 16000),
            'format' => $file->getClientOriginalExtension(),
            'file_size' => $file->getSize(),
            'status' => $request->label ? 'labeled' : 'unlabeled',
            'device_info' => $request->userAgent(),
        ]);

        if ($request->wantsJson()) {
            return response()->json($sample, 201);
        }

        return redirect()->route('dataset.index')->with('success', 'อัปโหลดเสียงสำเร็จ');
    }

    public function show(AudioSample $audioSample)
    {
        return view('dataset.show', compact('audioSample'));
    }

    public function update(Request $request, AudioSample $audioSample)
    {
        $request->validate([
            'label' => 'nullable|string|max:500',
            'transcript' => 'nullable|string',
            'category' => 'nullable|string',
            'status' => 'nullable|in:unlabeled,labeled,verified,rejected',
        ]);

        $audioSample->update($request->only(['label', 'transcript', 'category', 'status']));

        if ($request->wantsJson()) {
            return response()->json($audioSample);
        }

        return redirect()->back()->with('success', 'อัปเดตข้อมูลสำเร็จ');
    }

    public function destroy(AudioSample $audioSample)
    {
        \Storage::disk('public')->delete($audioSample->file_path);
        $audioSample->delete();

        if (request()->wantsJson()) {
            return response()->json(['message' => 'ลบสำเร็จ']);
        }

        return redirect()->route('dataset.index')->with('success', 'ลบข้อมูลสำเร็จ');
    }

    public function bulkAction(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'action' => 'required|in:delete,verify,label',
        ]);

        $samples = AudioSample::whereIn('id', $request->ids);

        switch ($request->action) {
            case 'delete':
                foreach ($samples->get() as $sample) {
                    \Storage::disk('public')->delete($sample->file_path);
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
