<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;

class RecordController extends Controller
{
    private const MAX_AUDIO_BYTES = 50 * 1024 * 1024; // 50MB

    public function index(): View
    {
        $recentRecordings = AudioSample::latest()->take(20)->get();
        $chants = $this->getChantList();
        return view('record.index', compact('recentRecordings', 'chants'));
    }

    public function storeRecording(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'audio_data' => 'required|string',
            'category' => 'required|in:daily,protection,meditation,merit,sutra',
            'chant_name' => 'nullable|string|max:255',
            'transcript' => 'nullable|string|max:5000',
            'duration' => 'required|numeric|min:0.1|max:3600',
        ]);

        $audioData = base64_decode($validated['audio_data'], true);
        if ($audioData === false) {
            return response()->json(['error' => 'Invalid base64 audio data'], 422);
        }

        if (strlen($audioData) > self::MAX_AUDIO_BYTES) {
            return response()->json(['error' => 'Audio data exceeds maximum size'], 422);
        }

        $filename = Str::uuid() . '.wav';
        $path = 'audio_samples/' . $filename;

        Storage::disk('public')->put($path, $audioData);

        $sample = AudioSample::create([
            'filename' => $filename,
            'original_name' => ($validated['chant_name'] ?? 'recording') . '.wav',
            'file_path' => $path,
            'category' => $validated['category'],
            'label' => $validated['chant_name'] ?? null,
            'transcript' => $validated['transcript'] ?? null,
            'duration' => $validated['duration'],
            'sample_rate' => 16000,
            'format' => 'wav',
            'file_size' => strlen($audioData),
            'status' => !empty($validated['transcript']) ? 'labeled' : 'unlabeled',
            'device_info' => $request->userAgent(),
        ]);

        return response()->json($sample, 201);
    }

    private function getChantList(): array
    {
        return [
            ['id' => 'namo', 'name' => 'นะโม ตัสสะ', 'category' => 'daily'],
            ['id' => 'tisarana', 'name' => 'ไตรสรณคมน์', 'category' => 'daily'],
            ['id' => 'pancasila', 'name' => 'ศีล 5', 'category' => 'daily'],
            ['id' => 'itipiso', 'name' => 'อิติปิโส', 'category' => 'daily'],
            ['id' => 'karaniya', 'name' => 'กรณียเมตตสูตร', 'category' => 'sutra'],
            ['id' => 'mangala', 'name' => 'มงคลสูตร', 'category' => 'sutra'],
            ['id' => 'ratana', 'name' => 'รตนสูตร', 'category' => 'protection'],
            ['id' => 'jayamangala', 'name' => 'ชัยมงคลคาถา', 'category' => 'protection'],
            ['id' => 'metta', 'name' => 'แผ่เมตตา', 'category' => 'merit'],
            ['id' => 'patthana', 'name' => 'อุทิศส่วนกุศล', 'category' => 'merit'],
            ['id' => 'anapanasati', 'name' => 'อานาปานสติ', 'category' => 'meditation'],
            ['id' => 'buddhanussati', 'name' => 'พุทธานุสสติ', 'category' => 'meditation'],
        ];
    }
}
