@extends('layouts.app')
@section('title', 'จัดการโมเดล - Aipray AI')
@section('page-title', 'จัดการโมเดล')

@section('content')
<!-- Toolbar -->
<div class="glass rounded-xl p-4 mb-6 flex items-center justify-between">
    <div class="flex gap-2">
        <select id="model-filter" class="bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" onchange="filterModels(this.value)">
            <option value="all">ทุกสถานะ</option>
            <option value="active">ใช้งานอยู่</option>
            <option value="deployed">Deploy แล้ว</option>
            <option value="archived">เก็บถาวร</option>
        </select>
    </div>
    <p class="text-sm text-gray-500">ทั้งหมด {{ $models->count() }} โมเดล</p>
</div>

<!-- Models Grid -->
<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4" id="models-grid">
    @forelse($models as $model)
    <div class="glass rounded-xl p-5 hover:glow-gold transition model-card" data-status="{{ $model->status }}">
        <div class="flex items-start justify-between mb-3">
            <div>
                <h3 class="text-base font-semibold text-gray-200">{{ $model->name }}</h3>
                <p class="text-xs text-gray-500">v{{ $model->version }} &middot; {{ $model->base_model }}</p>
            </div>
            <span class="px-2 py-0.5 rounded-full text-xs
                {{ $model->status === 'deployed' ? 'bg-green-500/20 text-green-400' :
                   ($model->status === 'active' ? 'bg-blue-500/20 text-blue-400' : 'bg-gray-500/20 text-gray-400') }}">
                {{ $model->status === 'deployed' ? '🚀 Deployed' : ($model->status === 'active' ? 'Active' : 'Archived') }}
            </span>
        </div>

        <!-- Metrics -->
        <div class="grid grid-cols-3 gap-2 mb-4">
            <div class="bg-temple-50/30 rounded-lg p-2 text-center">
                <p class="text-lg font-bold {{ ($model->accuracy ?? 0) >= 90 ? 'text-green-400' : (($model->accuracy ?? 0) >= 70 ? 'text-yellow-400' : 'text-red-400') }}">
                    {{ number_format($model->accuracy ?? 0, 1) }}%
                </p>
                <p class="text-[10px] text-gray-500">Accuracy</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-2 text-center">
                <p class="text-lg font-bold text-yellow-400">{{ number_format($model->wer ?? 0, 1) }}%</p>
                <p class="text-[10px] text-gray-500">WER</p>
            </div>
            <div class="bg-temple-50/30 rounded-lg p-2 text-center">
                <p class="text-lg font-bold text-blue-400">{{ number_format($model->cer ?? 0, 1) }}%</p>
                <p class="text-[10px] text-gray-500">CER</p>
            </div>
        </div>

        <!-- Info -->
        <div class="space-y-1 mb-4 text-xs text-gray-500">
            <div class="flex justify-between">
                <span>ตัวอย่างที่เทรน</span>
                <span class="text-gray-400">{{ number_format($model->total_samples_trained) }}</span>
            </div>
            <div class="flex justify-between">
                <span>ชั่วโมงเทรน</span>
                <span class="text-gray-400">{{ $model->total_hours_trained }}h</span>
            </div>
            <div class="flex justify-between">
                <span>ขนาด</span>
                <span class="text-gray-400">{{ $model->file_size_formatted }}</span>
            </div>
            <div class="flex justify-between">
                <span>สร้างเมื่อ</span>
                <span class="text-gray-400">{{ $model->created_at->format('d/m/Y') }}</span>
            </div>
        </div>

        <!-- Actions -->
        <div class="flex gap-2">
            @if($model->status !== 'deployed')
            <button onclick="deployModel({{ $model->id }})" class="flex-1 py-2 text-xs font-medium rounded-lg gradient-gold text-white hover:opacity-90 transition">
                <i class="fas fa-rocket mr-1"></i> Deploy
            </button>
            @else
            <span class="flex-1 py-2 text-xs font-medium rounded-lg bg-green-500/20 text-green-400 text-center">
                <i class="fas fa-check-circle mr-1"></i> กำลังใช้งาน
            </span>
            @endif
            <a href="{{ route('models.show', $model) }}" class="px-3 py-2 text-xs rounded-lg bg-gray-700/30 text-gray-400 hover:bg-gray-700/50 transition">
                <i class="fas fa-info-circle"></i>
            </a>
            @if($model->status !== 'deployed')
            <form method="POST" action="{{ route('models.destroy', $model) }}" onsubmit="return confirm('ยืนยันการลบโมเดล?')">
                @csrf @method('DELETE')
                <button type="submit" class="px-3 py-2 text-xs rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500/20 transition">
                    <i class="fas fa-trash"></i>
                </button>
            </form>
            @endif
        </div>
    </div>
    @empty
    <div class="col-span-full glass rounded-xl p-12 text-center">
        <i class="fas fa-cubes text-4xl text-gray-600 mb-3"></i>
        <p class="text-lg text-gray-400">ยังไม่มีโมเดล</p>
        <p class="text-sm text-gray-600 mt-1">เทรนโมเดลแรกของคุณเพื่อเริ่มใช้งาน</p>
        <a href="{{ route('training.index') }}" class="inline-block mt-4 px-6 py-2.5 gradient-gold rounded-lg text-sm text-white hover:opacity-90 transition">
            <i class="fas fa-brain mr-1"></i> ไปหน้าเทรน
        </a>
    </div>
    @endforelse
</div>
@endsection

@push('scripts')
<script>
async function deployModel(id) {
    if (!confirm('ยืนยันการ Deploy โมเดลนี้? โมเดลอื่นที่ Deploy อยู่จะถูกเปลี่ยนเป็น Active')) return;
    try {
        await apiCall(`/models/${id}/deploy`, 'POST');
        showToast('Deploy สำเร็จ!', 'success');
        setTimeout(() => location.reload(), 1000);
    } catch (err) {
        showToast('เกิดข้อผิดพลาด', 'error');
    }
}

function filterModels(status) {
    document.querySelectorAll('.model-card').forEach(card => {
        card.style.display = (status === 'all' || card.dataset.status === status) ? '' : 'none';
    });
}
</script>
@endpush
