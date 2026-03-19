@extends('layouts.app')
@section('title', 'แดชบอร์ด - Aipray AI Training')
@section('page-title', 'แดชบอร์ด')

@section('content')
<!-- Stats Cards -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
    <div class="glass rounded-xl p-5 glow-gold stat-card fade-in">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-gray-500 text-xs uppercase tracking-wide">ตัวอย่างเสียง</p>
                <h3 class="text-2xl font-bold text-gray-100 mt-1">{{ formatNumber($totalSamples) }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-blue-500/20 flex items-center justify-center">
                <i class="fas fa-microphone text-blue-400 text-lg"></i>
            </div>
        </div>
        <div class="mt-3 flex items-center gap-1 text-xs text-green-400">
            <i class="fas fa-arrow-up"></i> <span>12% จากสัปดาห์ก่อน</span>
        </div>
    </div>

    <div class="glass rounded-xl p-5 glow-gold stat-card fade-in" style="animation-delay: 0.1s">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-gray-500 text-xs uppercase tracking-wide">ชั่วโมงเสียง</p>
                <h3 class="text-2xl font-bold text-gray-100 mt-1">{{ $totalHours }}h</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-green-500/20 flex items-center justify-center">
                <i class="fas fa-clock text-green-400 text-lg"></i>
            </div>
        </div>
        <div class="mt-3 flex items-center gap-1 text-xs text-green-400">
            <i class="fas fa-arrow-up"></i> <span>8% จากสัปดาห์ก่อน</span>
        </div>
    </div>

    <div class="glass rounded-xl p-5 glow-gold stat-card fade-in" style="animation-delay: 0.2s">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-gray-500 text-xs uppercase tracking-wide">ความแม่นยำ</p>
                <h3 class="text-2xl font-bold text-gray-100 mt-1">{{ number_format($bestAccuracy, 1) }}%</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-purple-500/20 flex items-center justify-center">
                <i class="fas fa-brain text-purple-400 text-lg"></i>
            </div>
        </div>
        <div class="mt-3 flex items-center gap-1 text-xs text-green-400">
            <i class="fas fa-arrow-up"></i> <span>5% จากเวอร์ชันก่อน</span>
        </div>
    </div>

    <div class="glass rounded-xl p-5 glow-gold stat-card fade-in" style="animation-delay: 0.3s">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-gray-500 text-xs uppercase tracking-wide">โมเดลทั้งหมด</p>
                <h3 class="text-2xl font-bold text-gray-100 mt-1">{{ $modelsCount }}</h3>
            </div>
            <div class="w-12 h-12 rounded-xl bg-gold-500/20 flex items-center justify-center">
                <i class="fas fa-cubes text-gold-400 text-lg"></i>
            </div>
        </div>
        <div class="mt-3 flex items-center gap-1 text-xs text-gray-500">
            <i class="fas fa-minus"></i> <span>ไม่เปลี่ยนแปลง</span>
        </div>
    </div>
</div>

<!-- Charts Row -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
    <!-- Accuracy Chart -->
    <div class="glass rounded-xl p-5">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-gray-300"><i class="fas fa-chart-area text-gold-500 mr-2"></i>ความแม่นยำในการเทรน</h3>
        </div>
        <canvas id="accuracyChart" height="200"></canvas>
    </div>

    <!-- Category Chart -->
    <div class="glass rounded-xl p-5">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-gray-300"><i class="fas fa-chart-bar text-gold-500 mr-2"></i>ข้อมูลเสียงตามหมวดหมู่</h3>
        </div>
        <canvas id="categoryChart" height="200"></canvas>
    </div>
</div>

<!-- Activity & Training Status -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Recent Activity -->
    <div class="glass rounded-xl p-5">
        <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-history text-gold-500 mr-2"></i>กิจกรรมล่าสุด</h3>
        <div class="space-y-3">
            @forelse($recentSamples as $sample)
            <div class="flex items-center gap-3 p-3 rounded-lg bg-temple-50/30 hover:bg-temple-50/50 transition">
                <div class="w-8 h-8 rounded-lg {{ $sample->status === 'verified' ? 'bg-green-500/20' : ($sample->status === 'labeled' ? 'bg-blue-500/20' : 'bg-gray-500/20') }} flex items-center justify-center flex-shrink-0">
                    <i class="fas fa-{{ $sample->status === 'verified' ? 'check' : ($sample->status === 'labeled' ? 'tag' : 'microphone') }} text-xs {{ $sample->status === 'verified' ? 'text-green-400' : ($sample->status === 'labeled' ? 'text-blue-400' : 'text-gray-400') }}"></i>
                </div>
                <div class="flex-1 min-w-0">
                    <p class="text-sm text-gray-300 truncate">{{ $sample->original_name }}</p>
                    <p class="text-xs text-gray-500">{{ $sample->category }} &middot; {{ $sample->duration_formatted }}</p>
                </div>
                <span class="text-xs text-gray-600">{{ $sample->created_at->diffForHumans() }}</span>
            </div>
            @empty
            <div class="text-center py-8 text-gray-600">
                <i class="fas fa-inbox text-3xl mb-2"></i>
                <p>ยังไม่มีกิจกรรม</p>
            </div>
            @endforelse
        </div>
    </div>

    <!-- Training Jobs -->
    <div class="glass rounded-xl p-5">
        <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-tasks text-gold-500 mr-2"></i>สถานะการเทรน</h3>
        <div class="space-y-3">
            @forelse($recentJobs as $job)
            <div class="p-3 rounded-lg bg-temple-50/30">
                <div class="flex items-center justify-between mb-2">
                    <span class="text-sm text-gray-300 font-medium">{{ $job->name }}</span>
                    <span class="px-2 py-0.5 rounded-full text-xs
                        {{ $job->status === 'completed' ? 'bg-green-500/20 text-green-400' :
                           ($job->status === 'running' ? 'bg-blue-500/20 text-blue-400' :
                           ($job->status === 'failed' ? 'bg-red-500/20 text-red-400' : 'bg-gray-500/20 text-gray-400')) }}">
                        {{ $job->status }}
                    </span>
                </div>
                <div class="w-full bg-temple-300/30 rounded-full h-1.5">
                    <div class="gradient-gold h-1.5 rounded-full transition-all" style="width: {{ $job->progress }}%"></div>
                </div>
                <div class="flex items-center justify-between mt-1 text-xs text-gray-500">
                    <span>Epoch {{ $job->current_epoch }}/{{ $job->epochs }}</span>
                    @if($job->accuracy)
                    <span>{{ number_format($job->accuracy, 1) }}% acc</span>
                    @endif
                </div>
            </div>
            @empty
            <div class="text-center py-8 text-gray-600">
                <i class="fas fa-brain text-3xl mb-2"></i>
                <p>ยังไม่มีการเทรน</p>
                <a href="{{ route('training.index') }}" class="text-gold-500 text-sm hover:underline mt-1 inline-block">เริ่มเทรนโมเดลแรก</a>
            </div>
            @endforelse
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Accuracy Chart
    const accCtx = document.getElementById('accuracyChart');
    if (accCtx) {
        const accData = @json($accuracyHistory);
        new Chart(accCtx, {
            type: 'line',
            data: {
                labels: accData.length > 0 ? accData.map(d => d.name || '') : ['ยังไม่มีข้อมูล'],
                datasets: [{
                    label: 'Accuracy (%)',
                    data: accData.length > 0 ? accData.map(d => d.accuracy) : [0],
                    borderColor: '#D4A647',
                    backgroundColor: 'rgba(212,166,71,0.1)',
                    fill: true,
                    tension: 0.4,
                    pointRadius: 3,
                    pointBackgroundColor: '#D4A647',
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { beginAtZero: true, max: 100, grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#666' } },
                    x: { grid: { display: false }, ticks: { color: '#666', maxRotation: 45 } }
                }
            }
        });
    }

    // Category Chart
    const catCtx = document.getElementById('categoryChart');
    if (catCtx) {
        const catData = @json($categories);
        const catLabels = { daily: 'ประจำวัน', protection: 'ป้องกัน', meditation: 'สมาธิ', merit: 'แผ่เมตตา', sutra: 'พระสูตร', general: 'ทั่วไป' };
        const catColors = ['#D4A647', '#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444'];
        new Chart(catCtx, {
            type: 'doughnut',
            data: {
                labels: catData.length > 0 ? catData.map(d => catLabels[d.category] || d.category) : ['ยังไม่มีข้อมูล'],
                datasets: [{
                    data: catData.length > 0 ? catData.map(d => d.count) : [1],
                    backgroundColor: catColors,
                    borderColor: '#0D0D0D',
                    borderWidth: 3,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'right', labels: { color: '#999', padding: 15, usePointStyle: true } }
                }
            }
        });
    }
});
</script>
@endpush

@php
function formatNumber($n) { return number_format($n); }
@endphp
