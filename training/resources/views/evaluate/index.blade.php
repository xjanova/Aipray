@extends('layouts.app')
@section('title', 'ทดสอบ & ประเมิน - Aipray AI')
@section('page-title', 'ทดสอบ & ประเมินโมเดล')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <div class="lg:col-span-2">
        <div class="glass rounded-xl p-6">
            <h3 class="text-lg font-semibold text-gray-200 mb-4"><i class="fas fa-flask text-gold-500 mr-2"></i>ทดสอบโมเดล</h3>

            <!-- Model Selection -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <div>
                    <label class="block text-sm text-gray-400 mb-1">เลือกโมเดล</label>
                    <select id="eval-model" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        @forelse($models as $model)
                        <option value="{{ $model->id }}">{{ $model->name }} ({{ number_format($model->accuracy ?? 0, 1) }}%)</option>
                        @empty
                        <option value="">ยังไม่มีโมเดล</option>
                        @endforelse
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">วิธีทดสอบ</label>
                    <div class="flex gap-2">
                        <button class="eval-tab active flex-1 py-2 rounded-lg text-sm font-medium transition" data-mode="live">
                            <i class="fas fa-microphone mr-1"></i> พูดสด
                        </button>
                        <button class="eval-tab flex-1 py-2 rounded-lg text-sm font-medium transition" data-mode="text">
                            <i class="fas fa-keyboard mr-1"></i> ข้อความ
                        </button>
                        <button class="eval-tab flex-1 py-2 rounded-lg text-sm font-medium transition" data-mode="batch">
                            <i class="fas fa-layer-group mr-1"></i> ชุดทดสอบ
                        </button>
                    </div>
                </div>
            </div>

            <!-- Live Test Mode -->
            <div class="eval-mode active" id="mode-live">
                <div class="bg-temple-50/50 rounded-xl p-6 text-center mb-4">
                    <canvas id="eval-visualizer" width="600" height="80" class="w-full rounded-lg mb-4"></canvas>
                    <button id="eval-record-btn" class="w-20 h-20 rounded-full gradient-gold flex items-center justify-center text-white text-3xl hover:opacity-90 transition shadow-lg mx-auto">
                        <i class="fas fa-microphone"></i>
                    </button>
                    <p class="text-sm text-gray-500 mt-3">กดเพื่อเริ่มพูด แล้วกดอีกครั้งเพื่อหยุด</p>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">ข้อความอ้างอิง (Reference)</label>
                    <textarea id="eval-reference" rows="2" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="พิมพ์ข้อความที่ถูกต้อง เพื่อเปรียบเทียบ..."></textarea>
                </div>
            </div>

            <!-- Text Test Mode -->
            <div class="eval-mode hidden" id="mode-text">
                <div class="space-y-4">
                    <div>
                        <label class="block text-sm text-gray-400 mb-1">ข้อความที่รู้จำได้ (Recognized)</label>
                        <textarea id="text-recognized" rows="3" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="ใส่ข้อความที่โมเดลรู้จำได้..."></textarea>
                    </div>
                    <div>
                        <label class="block text-sm text-gray-400 mb-1">ข้อความอ้างอิง (Reference)</label>
                        <textarea id="text-reference" rows="3" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="ใส่ข้อความที่ถูกต้อง..."></textarea>
                    </div>
                    <button id="text-eval-btn" class="px-6 py-2.5 gradient-gold rounded-lg text-sm font-medium text-white hover:opacity-90 transition">
                        <i class="fas fa-calculator mr-1"></i> คำนวณ
                    </button>
                </div>
            </div>

            <!-- Batch Test Mode -->
            <div class="eval-mode hidden" id="mode-batch">
                <div class="text-center py-6">
                    <p class="text-gray-400 mb-4">ทดสอบโมเดลกับชุดข้อมูลทดสอบทั้งหมด</p>
                    <button id="batch-eval-btn" class="px-6 py-3 gradient-gold rounded-lg text-sm font-semibold text-white hover:opacity-90 transition shadow-lg">
                        <i class="fas fa-play mr-2"></i>เริ่มทดสอบชุด
                    </button>
                </div>
                <div id="batch-results" class="hidden mt-4">
                    <canvas id="batch-chart" height="250"></canvas>
                </div>
            </div>

            <!-- Results -->
            <div id="eval-results" class="hidden mt-6">
                <h4 class="text-sm font-semibold text-gray-300 mb-3"><i class="fas fa-poll text-gold-500 mr-1"></i> ผลการทดสอบ</h4>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
                    <div class="bg-green-500/10 border border-green-500/20 rounded-lg p-3 text-center">
                        <p class="text-2xl font-bold text-green-400" id="result-accuracy">-</p>
                        <p class="text-xs text-gray-500">Accuracy</p>
                    </div>
                    <div class="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-3 text-center">
                        <p class="text-2xl font-bold text-yellow-400" id="result-wer">-</p>
                        <p class="text-xs text-gray-500">WER</p>
                    </div>
                    <div class="bg-blue-500/10 border border-blue-500/20 rounded-lg p-3 text-center">
                        <p class="text-2xl font-bold text-blue-400" id="result-cer">-</p>
                        <p class="text-xs text-gray-500">CER</p>
                    </div>
                    <div class="bg-purple-500/10 border border-purple-500/20 rounded-lg p-3 text-center">
                        <p class="text-2xl font-bold text-purple-400" id="result-latency">-</p>
                        <p class="text-xs text-gray-500">Latency</p>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4" id="text-comparison" style="display:none;">
                    <div class="bg-temple-50/30 rounded-lg p-4">
                        <p class="text-xs text-gray-500 mb-1">รู้จำได้</p>
                        <p class="text-sm text-gray-300" id="result-recognized"></p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-4">
                        <p class="text-xs text-gray-500 mb-1">อ้างอิง</p>
                        <p class="text-sm text-gray-300" id="result-reference"></p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Eval History -->
    <div>
        <div class="glass rounded-xl p-5 mb-4">
            <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-chart-pie text-gold-500 mr-2"></i>ภาพรวมผลการประเมิน</h3>
            <canvas id="eval-overview-chart" height="200"></canvas>
        </div>

        <div class="glass rounded-xl p-5">
            <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-history text-gold-500 mr-2"></i>ประวัติการทดสอบ</h3>
            <div class="space-y-2 max-h-[400px] overflow-y-auto">
                @forelse($recentEvals as $eval)
                <div class="p-3 rounded-lg bg-temple-50/30">
                    <div class="flex items-center justify-between mb-1">
                        <span class="text-xs text-gray-500">{{ $eval->aiModel->name ?? 'Unknown' }}</span>
                        <span class="text-xs px-1.5 py-0.5 rounded {{ $eval->eval_type === 'batch' ? 'bg-purple-500/20 text-purple-400' : 'bg-blue-500/20 text-blue-400' }}">{{ $eval->eval_type }}</span>
                    </div>
                    <div class="flex items-center gap-3 text-xs">
                        <span class="text-green-400">{{ number_format($eval->accuracy, 1) }}% acc</span>
                        <span class="text-yellow-400">{{ number_format($eval->wer, 1) }}% WER</span>
                        <span class="text-gray-600">{{ $eval->created_at->diffForHumans() }}</span>
                    </div>
                </div>
                @empty
                <p class="text-center text-gray-600 py-4 text-sm">ยังไม่มีประวัติ</p>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection

@push('styles')
<style>
    .eval-tab { background: rgba(26,26,46,0.5); color: #666; border: 1px solid rgba(212,166,71,0.1); }
    .eval-tab.active { background: linear-gradient(135deg, rgba(212,166,71,0.2), rgba(212,166,71,0.1)); color: #D4A647; border-color: rgba(212,166,71,0.3); }
    .eval-tab:hover:not(.active) { background: rgba(212,166,71,0.05); }
</style>
@endpush

@push('scripts')
<script>
// Tab switching
document.querySelectorAll('.eval-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        document.querySelectorAll('.eval-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.eval-mode').forEach(m => m.classList.add('hidden'));
        tab.classList.add('active');
        document.getElementById('mode-' + tab.dataset.mode).classList.remove('hidden');
    });
});

// Text evaluation
document.getElementById('text-eval-btn')?.addEventListener('click', async () => {
    const modelId = document.getElementById('eval-model').value;
    if (!modelId) return showToast('กรุณาเลือกโมเดล', 'warning');

    const recognized = document.getElementById('text-recognized').value;
    const reference = document.getElementById('text-reference').value;
    if (!recognized || !reference) return showToast('กรุณากรอกข้อความทั้งสองช่อง', 'warning');

    try {
        const result = await apiCall('{{ route("evaluate.run") }}', 'POST', {
            model_id: modelId,
            eval_type: 'live',
            recognized_text: recognized,
            reference_text: reference,
        });

        showResults(result);
        showToast('ประเมินสำเร็จ!', 'success');
    } catch (err) {
        showToast('เกิดข้อผิดพลาด', 'error');
    }
});

// Batch evaluation
document.getElementById('batch-eval-btn')?.addEventListener('click', async () => {
    const modelId = document.getElementById('eval-model').value;
    if (!modelId) return showToast('กรุณาเลือกโมเดล', 'warning');

    const btn = document.getElementById('batch-eval-btn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>กำลังทดสอบ...';

    try {
        const result = await apiCall('{{ route("evaluate.batch") }}', 'POST', { model_id: modelId });

        document.getElementById('batch-results').classList.remove('hidden');
        document.getElementById('eval-results').classList.remove('hidden');
        document.getElementById('result-accuracy').textContent = result.average_accuracy.toFixed(1) + '%';
        document.getElementById('result-wer').textContent = result.average_wer.toFixed(1) + '%';
        document.getElementById('result-cer').textContent = result.average_cer.toFixed(1) + '%';
        document.getElementById('result-latency').textContent = '-';

        // Batch chart
        const catLabels = { daily:'ประจำวัน', protection:'ป้องกัน', meditation:'สมาธิ', merit:'แผ่เมตตา', sutra:'พระสูตร' };
        new Chart(document.getElementById('batch-chart'), {
            type: 'bar',
            data: {
                labels: result.categories.map(c => catLabels[c.category] || c.category),
                datasets: [
                    { label: 'Accuracy (%)', data: result.categories.map(c => c.accuracy), backgroundColor: 'rgba(212,166,71,0.5)', borderColor: '#D4A647', borderWidth: 1 },
                    { label: 'WER (%)', data: result.categories.map(c => c.wer), backgroundColor: 'rgba(245,158,11,0.3)', borderColor: '#f59e0b', borderWidth: 1 },
                ]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { labels: { color: '#999' } } },
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#666' } },
                    x: { grid: { display: false }, ticks: { color: '#666' } }
                }
            }
        });

        showToast('ทดสอบชุดเสร็จสิ้น!', 'success');
    } catch (err) {
        showToast('เกิดข้อผิดพลาด', 'error');
    }

    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-play mr-2"></i>เริ่มทดสอบชุด';
});

function showResults(result) {
    document.getElementById('eval-results').classList.remove('hidden');
    document.getElementById('result-accuracy').textContent = (result.accuracy?.toFixed(1) ?? '-') + '%';
    document.getElementById('result-wer').textContent = (result.wer?.toFixed(1) ?? '-') + '%';
    document.getElementById('result-cer').textContent = (result.cer?.toFixed(1) ?? '-') + '%';
    document.getElementById('result-latency').textContent = (result.latency_ms ?? '-') + 'ms';

    if (result.recognized_text || result.reference_text) {
        document.getElementById('text-comparison').style.display = 'grid';
        document.getElementById('result-recognized').textContent = result.recognized_text || '-';
        document.getElementById('result-reference').textContent = result.reference_text || '-';
    }
}

// Overview chart
@if($recentEvals->isNotEmpty())
new Chart(document.getElementById('eval-overview-chart'), {
    type: 'radar',
    data: {
        labels: ['Accuracy', 'WER (inv)', 'CER (inv)', 'Speed', 'Stability'],
        datasets: [{
            label: 'ประสิทธิภาพ',
            data: [
                {{ $recentEvals->avg('accuracy') ?? 0 }},
                {{ 100 - ($recentEvals->avg('wer') ?? 50) }},
                {{ 100 - ($recentEvals->avg('cer') ?? 30) }},
                85,
                90,
            ],
            borderColor: '#D4A647',
            backgroundColor: 'rgba(212,166,71,0.15)',
            pointBackgroundColor: '#D4A647',
        }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { r: { beginAtZero: true, max: 100, grid: { color: 'rgba(255,255,255,0.05)' }, pointLabels: { color: '#999' }, ticks: { display: false } } }
    }
});
@endif
</script>
@endpush
