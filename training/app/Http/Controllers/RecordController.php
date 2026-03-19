<?php

namespace App\Http\Controllers;

use App\Models\AudioSample;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RecordController extends Controller
{
    public function index()
    {
        $recentRecordings = AudioSample::latest()->take(20)->get();
        $chants = $this->getChantList();
        return view('record.index', compact('recentRecordings', 'chants'));
    }

    public function storeRecording(Request $request)
    {
        $request->validate([
            'audio_data' => 'required|string',
            'category' => 'required|string',
            'chant_name' => 'nullable|string',
            'transcript' => 'nullable|string',
            'duration' => 'required|numeric|min:0.1',
        ]);

        $audioData = base64_decode($request->audio_data);
        $filename = Str::uuid() . '.wav';
        $path = 'audio_samples/' . $filename;

        \Storage::disk('public')->put($path, $audioData);

        $sample = AudioSample::create([
            'filename' => $filename,
            'original_name' => $request->input('chant_name', 'recording') . '.wav',
            'file_path' => $path,
            'category' => $request->category,
            'label' => $request->chant_name,
            'transcript' => $request->transcript,
            'duration' => $request->duration,
            'sample_rate' => 16000,
            'format' => 'wav',
            'file_size' => strlen($audioData),
            'status' => $request->transcript ? 'labeled' : 'unlabeled',
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
