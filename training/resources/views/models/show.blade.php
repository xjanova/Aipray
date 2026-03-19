@extends('layouts.app')
@section('title', $aiModel->name . ' - Aipray AI')
@section('page-title', 'รายละเอียดโมเดล')

@section('content')
<div class="max-w-4xl mx-auto">
    <div class="glass rounded-xl p-6 mb-6">
        <div class="flex items-start justify-between mb-6">
            <div>
                <h2 class="text-xl font-bold text-gray-200">{{ $aiModel->name }}</h2>
                <p class="text-sm text-gray-500 mt-1">v{{ $aiModel->version }} &middot; Base: {{ $aiModel->base_model }} &middot; สร้าง: {{ $aiModel->created_at->format('d/m/Y H:i') }}</p>
            </div>
            <span class="px-3 py-1 rounded-full text-sm
                {{ $aiModel->status === 'deployed' ? 'bg-green-500/20 text-green-400' :
                   ($aiModel->status === 'active' ? 'bg-blue-500/20 text-blue-400' : 'bg-gray-500/20 text-gray-400') }}">
                {{ $aiModel->status }}
            </span>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-5 gap-3 mb-6">
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-2xl font-bold text-gold-400">{{ number_format($aiModel->accuracy ?? 0, 1) }}%</p>
                <p class="text-xs text-gray-500">Accuracy</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-2xl font-bold text-yellow-400">{{ number_format($aiModel->wer ?? 0, 1) }}%</p>
                <p class="text-xs text-gray-500">WER</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-2xl font-bold text-blue-400">{{ number_format($aiModel->cer ?? 0, 1) }}%</p>
                <p class="text-xs text-gray-500">CER</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-2xl font-bold text-green-400">{{ number_format($aiModel->total_samples_trained) }}</p>
                <p class="text-xs text-gray-500">Samples</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                <p class="text-2xl font-bold text-purple-400">{{ $aiModel->file_size_formatted }}</p>
                <p class="text-xs text-gray-500">Size</p>
            </div>
        </div>

        <!-- Training Job Info -->
        @if($aiModel->trainingJob)
        <div class="bg-temple-50/30 rounded-lg p-4 mb-6">
            <h4 class="text-sm font-semibold text-gray-300 mb-2"><i class="fas fa-cog text-gold-500 mr-1"></i> Training Configuration</h4>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                <div><span class="text-gray-500">Epochs:</span> <span class="text-gray-300">{{ $aiModel->trainingJob->epochs }}</span></div>
                <div><span class="text-gray-500">Batch Size:</span> <span class="text-gray-300">{{ $aiModel->trainingJob->batch_size }}</span></div>
                <div><span class="text-gray-500">Learning Rate:</span> <span class="text-gray-300">{{ $aiModel->trainingJob->learning_rate }}</span></div>
                <div><span class="text-gray-500">Optimizer:</span> <span class="text-gray-300">{{ $aiModel->trainingJob->optimizer }}</span></div>
            </div>
        </div>
        @endif

        <!-- Notes -->
        <form method="POST" action="{{ route('models.update', $aiModel) }}">
            @csrf @method('PUT')
            <div class="space-y-4">
                <div>
                    <label class="block text-sm text-gray-400 mb-1">บันทึก</label>
                    <textarea name="notes" rows="3" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">{{ $aiModel->notes }}</textarea>
                </div>
                <div class="flex gap-3">
                    <button type="submit" class="px-4 py-2 gradient-gold rounded-lg text-sm text-white hover:opacity-90 transition">
                        <i class="fas fa-save mr-1"></i> บันทึก
                    </button>
                    <a href="{{ route('models.index') }}" class="px-4 py-2 bg-gray-700/50 rounded-lg text-sm text-gray-400 hover:bg-gray-700 transition">กลับ</a>
                </div>
            </div>
        </form>
    </div>

    <!-- Evaluation History -->
    @if($aiModel->evaluations->isNotEmpty())
    <div class="glass rounded-xl p-6">
        <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-chart-line text-gold-500 mr-2"></i>ประวัติการประเมิน</h3>
        <div class="overflow-x-auto">
            <table class="w-full">
                <thead>
                    <tr class="border-b border-gold-500/10">
                        <th class="px-3 py-2 text-left text-xs text-gray-500">ประเภท</th>
                        <th class="px-3 py-2 text-left text-xs text-gray-500">Accuracy</th>
                        <th class="px-3 py-2 text-left text-xs text-gray-500">WER</th>
                        <th class="px-3 py-2 text-left text-xs text-gray-500">CER</th>
                        <th class="px-3 py-2 text-left text-xs text-gray-500">Latency</th>
                        <th class="px-3 py-2 text-left text-xs text-gray-500">วันที่</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gold-500/5">
                    @foreach($aiModel->evaluations->take(20) as $eval)
                    <tr class="hover:bg-gold-500/5">
                        <td class="px-3 py-2 text-xs"><span class="px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-400">{{ $eval->eval_type }}</span></td>
                        <td class="px-3 py-2 text-sm text-green-400">{{ number_format($eval->accuracy, 1) }}%</td>
                        <td class="px-3 py-2 text-sm text-yellow-400">{{ number_format($eval->wer, 1) }}%</td>
                        <td class="px-3 py-2 text-sm text-blue-400">{{ number_format($eval->cer, 1) }}%</td>
                        <td class="px-3 py-2 text-sm text-gray-400">{{ $eval->latency_ms }}ms</td>
                        <td class="px-3 py-2 text-xs text-gray-500">{{ $eval->created_at->format('d/m/Y H:i') }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif
</div>
@endsection
