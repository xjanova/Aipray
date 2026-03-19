@extends('layouts.app')
@section('title', 'เทรนโมเดล - Aipray AI')
@section('page-title', 'เทรนโมเดล')

@section('content')
<div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
    <!-- Training Config -->
    <div class="xl:col-span-2">
        <div class="glass rounded-xl p-6 mb-6">
            <h3 class="text-lg font-semibold text-gray-200 mb-4"><i class="fas fa-cogs text-gold-500 mr-2"></i>ตั้งค่าการเทรน</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                <div>
                    <label class="block text-sm text-gray-400 mb-1">โมเดลพื้นฐาน</label>
                    <select id="base-model" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="whisper-tiny">Whisper Tiny (39M)</option>
                        <option value="whisper-base" selected>Whisper Base (74M)</option>
                        <option value="whisper-small">Whisper Small (244M)</option>
                        <option value="whisper-medium">Whisper Medium (769M)</option>
                        <option value="sherpa-onnx">Sherpa-ONNX Thai</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">ชุดข้อมูล</label>
                    <select id="dataset-filter" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="all">ทั้งหมด ({{ $sampleCount }})</option>
                        <option value="labeled">ติดป้ายแล้ว ({{ $labeledCount }})</option>
                        <option value="verified">ตรวจสอบแล้ว</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">Learning Rate</label>
                    <input type="number" id="learning-rate" value="0.0001" step="0.00001" min="0.000001" max="0.1" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">Batch Size</label>
                    <select id="batch-size" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="4">4</option>
                        <option value="8" selected>8</option>
                        <option value="16">16</option>
                        <option value="32">32</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">Epochs</label>
                    <input type="number" id="epochs" value="10" min="1" max="100" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">Optimizer</label>
                    <select id="optimizer" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="adamw" selected>AdamW</option>
                        <option value="adam">Adam</option>
                        <option value="sgd">SGD</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">Train/Val Split</label>
                    <div class="flex items-center gap-2">
                        <input type="range" id="train-split" min="50" max="95" value="80" class="flex-1 accent-gold-500">
                        <span id="split-value" class="text-sm text-gold-400 w-10 text-right">80%</span>
                    </div>
                </div>
                <div class="md:col-span-2">
                    <label class="block text-sm text-gray-400 mb-2">Data Augmentation</label>
                    <div class="flex flex-wrap gap-4">
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="checkbox" id="aug-noise" checked class="rounded border-gray-600 text-gold-500 focus:ring-gold-500">
                            <span class="text-sm text-gray-400">Noise Injection</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="checkbox" id="aug-speed" checked class="rounded border-gray-600 text-gold-500 focus:ring-gold-500">
                            <span class="text-sm text-gray-400">Speed Perturbation</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="checkbox" id="aug-pitch" class="rounded border-gray-600 text-gold-500 focus:ring-gold-500">
                            <span class="text-sm text-gray-400">Pitch Shift</span>
                        </label>
                    </div>
                </div>
            </div>

            <div class="flex gap-3">
                <button id="start-train-btn" class="px-6 py-3 gradient-gold rounded-lg text-sm font-semibold text-white hover:opacity-90 transition shadow-lg">
                    <i class="fas fa-play mr-2"></i>เริ่มเทรน
                </button>
                <button id="stop-train-btn" disabled class="px-6 py-3 bg-red-500/20 rounded-lg text-sm font-medium text-red-400 hover:bg-red-500/30 transition disabled:opacity-30">
                    <i class="fas fa-stop mr-2"></i>หยุดเทรน
                </button>
            </div>
        </div>

        <!-- Training Progress -->
        <div id="progress-section" class="glass rounded-xl p-6 hidden">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-gray-200"><i class="fas fa-spinner fa-pulse text-gold-500 mr-2" id="progress-spinner"></i>ความคืบหน้า</h3>
                <span class="text-sm text-gray-500" id="elapsed-time">00:00:00</span>
            </div>

            <!-- Progress Ring -->
            <div class="flex flex-col md:flex-row items-center gap-6 mb-6">
                <div class="relative">
                    <svg class="w-32 h-32 transform -rotate-90" viewBox="0 0 160 160">
                        <circle cx="80" cy="80" r="70" stroke="rgba(212,166,71,0.1)" stroke-width="8" fill="none"/>
                        <circle id="progress-ring" cx="80" cy="80" r="70" stroke="#D4A647" stroke-width="8" fill="none"
                            stroke-dasharray="439.82" stroke-dashoffset="439.82" stroke-linecap="round" class="training-progress-ring"/>
                    </svg>
                    <div class="absolute inset-0 flex flex-col items-center justify-center">
                        <span class="text-2xl font-bold text-gold-400" id="progress-pct">0%</span>
                        <span class="text-xs text-gray-500">เสร็จสิ้น</span>
                    </div>
                </div>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-4 flex-1">
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">Epoch</p>
                        <p class="text-lg font-bold text-gray-200" id="epoch-display">0/10</p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">Train Loss</p>
                        <p class="text-lg font-bold text-blue-400" id="train-loss-display">-</p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">Val Loss</p>
                        <p class="text-lg font-bold text-purple-400" id="val-loss-display">-</p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">WER</p>
                        <p class="text-lg font-bold text-yellow-400" id="wer-display">-</p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">CER</p>
                        <p class="text-lg font-bold text-green-400" id="cer-display">-</p>
                    </div>
                    <div class="bg-temple-50/30 rounded-lg p-3 text-center">
                        <p class="text-xs text-gray-500">Accuracy</p>
                        <p class="text-lg font-bold text-gold-400" id="accuracy-display">-</p>
                    </div>
                </div>
            </div>

            <!-- Charts -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <div class="bg-temple-50/30 rounded-lg p-4">
                    <h4 class="text-sm text-gray-400 mb-2">Loss</h4>
                    <canvas id="loss-chart" height="180"></canvas>
                </div>
                <div class="bg-temple-50/30 rounded-lg p-4">
                    <h4 class="text-sm text-gray-400 mb-2">Error Rates</h4>
                    <canvas id="error-chart" height="180"></canvas>
                </div>
            </div>

            <!-- Training Log -->
            <div>
                <h4 class="text-sm text-gray-400 mb-2"><i class="fas fa-terminal mr-1"></i> Training Log</h4>
                <div id="training-log" class="bg-black/50 rounded-lg p-4 font-mono text-xs text-green-400 h-48 overflow-y-auto whitespace-pre-wrap"></div>
            </div>
        </div>
    </div>

    <!-- Training History Sidebar -->
    <div>
        <div class="glass rounded-xl p-5">
            <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-history text-gold-500 mr-2"></i>ประวัติการเทรน</h3>
            <div class="space-y-3">
                @forelse($jobs as $job)
                <div class="p-3 rounded-lg bg-temple-50/30 hover:bg-temple-50/50 transition cursor-pointer">
                    <div class="flex items-center justify-between mb-1">
                        <span class="text-sm text-gray-300 font-medium truncate">{{ $job->name }}</span>
                        <span class="px-2 py-0.5 rounded-full text-[10px]
                            {{ $job->status === 'completed' ? 'bg-green-500/20 text-green-400' :
                               ($job->status === 'running' ? 'bg-blue-500/20 text-blue-400' :
                               ($job->status === 'failed' ? 'bg-red-500/20 text-red-400' :
                               ($job->status === 'paused' ? 'bg-yellow-500/20 text-yellow-400' : 'bg-gray-500/20 text-gray-400'))) }}">
                            {{ $job->status }}
                        </span>
                    </div>
                    <div class="w-full bg-temple-300/30 rounded-full h-1 mt-1">
                        <div class="gradient-gold h-1 rounded-full" style="width: {{ $job->progress }}%"></div>
                    </div>
                    <div class="flex justify-between mt-1 text-[10px] text-gray-600">
                        <span>{{ $job->base_model }}</span>
                        <span>{{ $job->current_epoch }}/{{ $job->epochs }}</span>
                        @if($job->accuracy)<span>{{ number_format($job->accuracy, 1) }}%</span>@endif
                    </div>
                </div>
                @empty
                <div class="text-center py-6 text-gray-600">
                    <i class="fas fa-brain text-2xl mb-2"></i>
                    <p class="text-sm">ยังไม่มีประวัติ</p>
                </div>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
let currentJobId = null;
let trainingInterval = null;
let lossChart = null;
let errorChart = null;
let elapsedInterval = null;
let trainStartTime = null;

document.getElementById('train-split').addEventListener('input', function() {
    document.getElementById('split-value').textContent = this.value + '%';
});

document.getElementById('start-train-btn').addEventListener('click', startTraining);
document.getElementById('stop-train-btn').addEventListener('click', stopTraining);

async function startTraining() {
    const btn = document.getElementById('start-train-btn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>กำลังเริ่ม...';

    try {
        const job = await apiCall('{{ route("training.start") }}', 'POST', {
            base_model: document.getElementById('base-model').value,
            dataset_filter: document.getElementById('dataset-filter').value,
            learning_rate: parseFloat(document.getElementById('learning-rate').value),
            batch_size: parseInt(document.getElementById('batch-size').value),
            epochs: parseInt(document.getElementById('epochs').value),
            train_split: parseInt(document.getElementById('train-split').value),
            optimizer: document.getElementById('optimizer').value,
            aug_noise: document.getElementById('aug-noise').checked,
            aug_speed: document.getElementById('aug-speed').checked,
            aug_pitch: document.getElementById('aug-pitch').checked,
        });

        currentJobId = job.id;
        showToast('เริ่มเทรนโมเดลแล้ว!', 'success');

        document.getElementById('progress-section').classList.remove('hidden');
        document.getElementById('stop-train-btn').disabled = false;
        document.getElementById('training-log').textContent = job.log || '';

        initCharts();

        trainStartTime = Date.now();
        elapsedInterval = setInterval(() => {
            const s = Math.floor((Date.now() - trainStartTime) / 1000);
            document.getElementById('elapsed-time').textContent =
                `${String(Math.floor(s/3600)).padStart(2,'0')}:${String(Math.floor(s%3600/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`;
        }, 1000);

        // Simulate training epochs
        trainingInterval = setInterval(simulateEpoch, 2000);

    } catch (err) {
        showToast('เกิดข้อผิดพลาด: ' + err.message, 'error');
    }

    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-play mr-2"></i>เริ่มเทรน';
}

async function simulateEpoch() {
    if (!currentJobId) return;
    try {
        const job = await apiCall(`/training/${currentJobId}/simulate`, 'POST');
        updateProgress(job);

        if (job.status === 'completed') {
            clearInterval(trainingInterval);
            clearInterval(elapsedInterval);
            document.getElementById('stop-train-btn').disabled = true;
            document.getElementById('progress-spinner').className = 'fas fa-check-circle text-green-400 mr-2';
            showToast('เทรนเสร็จสมบูรณ์! โมเดลถูกบันทึกแล้ว', 'success');
        }
    } catch (err) {
        clearInterval(trainingInterval);
        showToast('เกิดข้อผิดพลาดระหว่างเทรน', 'error');
    }
}

async function stopTraining() {
    if (!currentJobId) return;
    clearInterval(trainingInterval);
    clearInterval(elapsedInterval);
    await apiCall(`/training/${currentJobId}/stop`, 'POST');
    document.getElementById('stop-train-btn').disabled = true;
    document.getElementById('progress-spinner').className = 'fas fa-pause-circle text-yellow-400 mr-2';
    showToast('หยุดเทรนแล้ว', 'warning');
}

function updateProgress(job) {
    const pct = job.epochs > 0 ? Math.round((job.current_epoch / job.epochs) * 100) : 0;
    document.getElementById('progress-pct').textContent = pct + '%';
    document.getElementById('epoch-display').textContent = `${job.current_epoch}/${job.epochs}`;
    document.getElementById('train-loss-display').textContent = job.training_loss?.toFixed(4) ?? '-';
    document.getElementById('val-loss-display').textContent = job.validation_loss?.toFixed(4) ?? '-';
    document.getElementById('wer-display').textContent = job.wer ? job.wer.toFixed(2) + '%' : '-';
    document.getElementById('cer-display').textContent = job.cer ? job.cer.toFixed(2) + '%' : '-';
    document.getElementById('accuracy-display').textContent = job.accuracy ? job.accuracy.toFixed(1) + '%' : '-';
    document.getElementById('training-log').textContent = job.log || '';
    document.getElementById('training-log').scrollTop = document.getElementById('training-log').scrollHeight;

    // Progress ring
    const ring = document.getElementById('progress-ring');
    const circumference = 2 * Math.PI * 70;
    ring.style.strokeDashoffset = circumference * (1 - pct / 100);

    // Update charts
    if (job.loss_history && lossChart) {
        lossChart.data.labels = job.loss_history.map(d => 'E' + d.epoch);
        lossChart.data.datasets[0].data = job.loss_history.map(d => d.train);
        lossChart.data.datasets[1].data = job.loss_history.map(d => d.val);
        lossChart.update('none');
    }
    if (job.metrics_history && errorChart) {
        errorChart.data.labels = job.metrics_history.map(d => 'E' + d.epoch);
        errorChart.data.datasets[0].data = job.metrics_history.map(d => d.wer);
        errorChart.data.datasets[1].data = job.metrics_history.map(d => d.cer);
        errorChart.update('none');
    }
}

function initCharts() {
    const chartOpts = {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#999', usePointStyle: true, padding: 10, font: { size: 10 } } } },
        scales: {
            y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#666', font: { size: 10 } } },
            x: { grid: { display: false }, ticks: { color: '#666', font: { size: 10 } } }
        }
    };

    if (lossChart) lossChart.destroy();
    lossChart = new Chart(document.getElementById('loss-chart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                { label: 'Train Loss', data: [], borderColor: '#3b82f6', tension: 0.4, pointRadius: 3, borderWidth: 2 },
                { label: 'Val Loss', data: [], borderColor: '#8b5cf6', tension: 0.4, pointRadius: 3, borderWidth: 2 },
            ]
        },
        options: chartOpts
    });

    if (errorChart) errorChart.destroy();
    errorChart = new Chart(document.getElementById('error-chart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                { label: 'WER (%)', data: [], borderColor: '#f59e0b', tension: 0.4, pointRadius: 3, borderWidth: 2 },
                { label: 'CER (%)', data: [], borderColor: '#10b981', tension: 0.4, pointRadius: 3, borderWidth: 2 },
            ]
        },
        options: chartOpts
    });
}
</script>
@endpush
