@extends('layouts.app')
@section('title', 'รายละเอียดเสียง - Aipray AI')
@section('page-title', 'รายละเอียดข้อมูลเสียง')

@section('content')
<div class="max-w-4xl mx-auto">
    <div class="glass rounded-xl p-6 mb-6">
        <div class="flex items-start justify-between mb-6">
            <div>
                <h2 class="text-xl font-bold text-gray-200">{{ $audioSample->original_name }}</h2>
                <p class="text-sm text-gray-500 mt-1">ID: {{ $audioSample->id }} &middot; {{ $audioSample->created_at->format('d/m/Y H:i') }}</p>
            </div>
            <span class="px-3 py-1 rounded-full text-sm
                {{ $audioSample->status === 'verified' ? 'bg-green-500/20 text-green-400' :
                   ($audioSample->status === 'labeled' ? 'bg-blue-500/20 text-blue-400' : 'bg-gray-500/20 text-gray-400') }}">
                {{ $audioSample->status }}
            </span>
        </div>

        <!-- Audio Player -->
        <div class="bg-temple-50/50 rounded-xl p-4 mb-6">
            <audio controls class="w-full" src="{{ asset('storage/' . $audioSample->file_path) }}"></audio>
        </div>

        <!-- Info Grid -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-xs text-gray-500">ความยาว</p>
                <p class="text-lg font-bold text-gray-200">{{ $audioSample->duration_formatted }}</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-xs text-gray-500">Sample Rate</p>
                <p class="text-lg font-bold text-gray-200">{{ number_format($audioSample->sample_rate) }} Hz</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-xs text-gray-500">รูปแบบ</p>
                <p class="text-lg font-bold text-gray-200 uppercase">{{ $audioSample->format }}</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-xs text-gray-500">ขนาด</p>
                <p class="text-lg font-bold text-gray-200">{{ round($audioSample->file_size / 1024, 1) }} KB</p>
            </div>
        </div>

        <!-- Edit Form -->
        <form method="POST" action="{{ route('dataset.update', $audioSample) }}">
            @csrf @method('PUT')
            <div class="space-y-4">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm text-gray-400 mb-1">หมวดหมู่</label>
                        <select name="category" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                            @foreach(['daily'=>'ประจำวัน','protection'=>'ป้องกัน','meditation'=>'สมาธิ','merit'=>'แผ่เมตตา','sutra'=>'พระสูตร'] as $val => $label)
                            <option value="{{ $val }}" {{ $audioSample->category === $val ? 'selected' : '' }}>{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm text-gray-400 mb-1">สถานะ</label>
                        <select name="status" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                            @foreach(['unlabeled'=>'ยังไม่ติดป้าย','labeled'=>'ติดป้ายแล้ว','verified'=>'ตรวจสอบแล้ว','rejected'=>'ปฏิเสธ'] as $val => $label)
                            <option value="{{ $val }}" {{ $audioSample->status === $val ? 'selected' : '' }}>{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">ป้ายกำกับ</label>
                    <input type="text" name="label" value="{{ $audioSample->label }}" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">คำถอดเสียง (Transcript)</label>
                    <textarea name="transcript" rows="4" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">{{ $audioSample->transcript }}</textarea>
                </div>
            </div>
            <div class="flex gap-3 mt-6">
                <button type="submit" class="px-6 py-2.5 gradient-gold rounded-lg text-sm font-medium text-white hover:opacity-90 transition">
                    <i class="fas fa-save mr-1"></i> บันทึก
                </button>
                <a href="{{ route('dataset.index') }}" class="px-6 py-2.5 bg-gray-700/50 rounded-lg text-sm text-gray-400 hover:bg-gray-700 transition">กลับ</a>
            </div>
        </form>
    </div>
</div>
@endsection
