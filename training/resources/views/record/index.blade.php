@extends('layouts.app')
@section('title', 'บันทึกเสียง - Aipray AI')
@section('page-title', 'บันทึกเสียง')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Main Recording Area -->
    <div class="lg:col-span-2">
        <div class="glass rounded-xl p-6">
            <h3 class="text-lg font-semibold text-gray-200 mb-4"><i class="fas fa-microphone text-gold-500 mr-2"></i>บันทึกเสียงสำหรับเทรน</h3>

            <!-- Config -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <div>
                    <label class="block text-sm text-gray-400 mb-1">เลือกบทสวด</label>
                    <select id="chant-select" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="">-- เลือกบทสวด --</option>
                        @foreach($chants as $chant)
                        <option value="{{ $chant['id'] }}" data-category="{{ $chant['category'] }}">{{ $chant['name'] }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">หมวดหมู่</label>
                    <select id="category-select" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30">
                        <option value="daily">บทสวดประจำวัน</option>
                        <option value="protection">บทป้องกัน</option>
                        <option value="meditation">บทสมาธิ</option>
                        <option value="merit">บทแผ่เมตตา</option>
                        <option value="sutra">พระสูตร</option>
                    </select>
                </div>
            </div>

            <!-- Transcript Input -->
            <div class="mb-6">
                <label class="block text-sm text-gray-400 mb-1">ข้อความสำหรับอ่าน (Transcript)</label>
                <textarea id="transcript-input" rows="3" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="พิมพ์ข้อความที่จะอ่านออกเสียง..."></textarea>
            </div>

            <!-- Visualizer -->
            <div class="bg-temple-50/50 rounded-xl p-4 mb-6">
                <canvas id="audio-visualizer" width="800" height="120" class="w-full rounded-lg"></canvas>
                <div class="flex justify-between mt-2 text-xs text-gray-500">
                    <span id="rec-time">00:00</span>
                    <span id="rec-status" class="text-gray-600">พร้อมบันทึก</span>
                    <span id="rec-format">WAV 16kHz Mono</span>
                </div>
            </div>

            <!-- Controls -->
            <div class="flex items-center justify-center gap-4 mb-6">
                <button id="record-btn" class="w-16 h-16 rounded-full gradient-gold flex items-center justify-center text-white text-2xl hover:opacity-90 transition shadow-lg hover:shadow-gold-500/30" title="บันทึก">
                    <i class="fas fa-microphone"></i>
                </button>
                <button id="stop-btn" disabled class="w-12 h-12 rounded-full bg-red-500/20 flex items-center justify-center text-red-400 text-lg hover:bg-red-500/30 transition disabled:opacity-30" title="หยุด">
                    <i class="fas fa-stop"></i>
                </button>
                <button id="play-btn" disabled class="w-12 h-12 rounded-full bg-green-500/20 flex items-center justify-center text-green-400 text-lg hover:bg-green-500/30 transition disabled:opacity-30" title="เล่น">
                    <i class="fas fa-play"></i>
                </button>
                <button id="save-btn" disabled class="w-12 h-12 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-400 text-lg hover:bg-blue-500/30 transition disabled:opacity-30" title="บันทึก">
                    <i class="fas fa-save"></i>
                </button>
            </div>

            <!-- Audio Info -->
            <div class="flex items-center justify-center gap-6 text-xs text-gray-500">
                <span><i class="fas fa-wave-square mr-1"></i> 16kHz</span>
                <span><i class="fas fa-volume-up mr-1"></i> Mono</span>
                <span><i class="fas fa-file-audio mr-1"></i> WAV</span>
                <span id="audio-level"><i class="fas fa-signal mr-1"></i> Level: <span id="level-value">0</span> dB</span>
            </div>
        </div>
    </div>

    <!-- Recent Recordings Sidebar -->
    <div>
        <div class="glass rounded-xl p-5">
            <h3 class="text-sm font-semibold text-gray-300 mb-4"><i class="fas fa-list text-gold-500 mr-2"></i>บันทึกล่าสุด</h3>
            <div class="space-y-2 max-h-[600px] overflow-y-auto" id="recent-list">
                @forelse($recentRecordings as $rec)
                <div class="p-3 rounded-lg bg-temple-50/30 hover:bg-temple-50/50 transition">
                    <div class="flex items-center gap-2 mb-1">
                        <i class="fas fa-file-audio text-gold-500/50 text-xs"></i>
                        <span class="text-sm text-gray-300 truncate">{{ $rec->original_name }}</span>
                    </div>
                    <div class="flex items-center justify-between text-xs text-gray-600">
                        <span>{{ $rec->duration_formatted }}</span>
                        <span>{{ $rec->created_at->diffForHumans() }}</span>
                    </div>
                </div>
                @empty
                <div class="text-center py-6 text-gray-600">
                    <i class="fas fa-microphone-slash text-2xl mb-2"></i>
                    <p class="text-sm">ยังไม่มีการบันทึก</p>
                </div>
                @endforelse
            </div>
        </div>

        <!-- Quick Stats -->
        <div class="glass rounded-xl p-5 mt-4">
            <h3 class="text-sm font-semibold text-gray-300 mb-3"><i class="fas fa-chart-simple text-gold-500 mr-2"></i>สถิติวันนี้</h3>
            <div class="space-y-3">
                <div class="flex justify-between items-center">
                    <span class="text-xs text-gray-500">บันทึกวันนี้</span>
                    <span class="text-sm font-bold text-gray-300" id="today-count">{{ $recentRecordings->where('created_at', '>=', now()->startOfDay())->count() }}</span>
                </div>
                <div class="flex justify-between items-center">
                    <span class="text-xs text-gray-500">ระยะเวลารวม</span>
                    <span class="text-sm font-bold text-gray-300">{{ gmdate('i:s', $recentRecordings->sum('duration')) }}</span>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
let mediaRecorder = null;
let audioChunks = [];
let audioBlob = null;
let audioUrl = null;
let audioContext = null;
let analyser = null;
let animationId = null;
let startTime = null;
let timerInterval = null;

const recordBtn = document.getElementById('record-btn');
const stopBtn = document.getElementById('stop-btn');
const playBtn = document.getElementById('play-btn');
const saveBtn = document.getElementById('save-btn');
const canvas = document.getElementById('audio-visualizer');
const ctx = canvas.getContext('2d');
const recTime = document.getElementById('rec-time');
const recStatus = document.getElementById('rec-status');

// Auto-select category when chant is selected
document.getElementById('chant-select')?.addEventListener('change', function() {
    const option = this.selectedOptions[0];
    if (option?.dataset.category) {
        document.getElementById('category-select').value = option.dataset.category;
    }
});

recordBtn.addEventListener('click', startRecording);
stopBtn.addEventListener('click', stopRecording);
playBtn.addEventListener('click', playRecording);
saveBtn.addEventListener('click', saveRecording);

async function startRecording() {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            audio: { sampleRate: 16000, channelCount: 1, echoCancellation: true, noiseSuppression: true }
        });

        audioContext = new AudioContext({ sampleRate: 16000 });
        analyser = audioContext.createAnalyser();
        analyser.fftSize = 2048;
        const source = audioContext.createMediaStreamSource(stream);
        source.connect(analyser);

        mediaRecorder = new MediaRecorder(stream, { mimeType: 'audio/webm;codecs=opus' });
        audioChunks = [];

        mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) audioChunks.push(e.data); };
        mediaRecorder.onstop = () => {
            audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            audioUrl = URL.createObjectURL(audioBlob);
            playBtn.disabled = false;
            saveBtn.disabled = false;
            stream.getTracks().forEach(t => t.stop());
        };

        mediaRecorder.start(100);
        recordBtn.classList.add('pulse-record');
        recordBtn.innerHTML = '<i class="fas fa-circle text-red-300"></i>';
        stopBtn.disabled = false;
        playBtn.disabled = true;
        saveBtn.disabled = true;
        recStatus.textContent = '🔴 กำลังบันทึก...';
        recStatus.classList.add('text-red-400');

        startTime = Date.now();
        timerInterval = setInterval(updateTimer, 100);
        drawVisualizer();

    } catch (err) {
        showToast('ไม่สามารถเข้าถึงไมโครโฟน: ' + err.message, 'error');
    }
}

function stopRecording() {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
        mediaRecorder.stop();
    }
    recordBtn.classList.remove('pulse-record');
    recordBtn.innerHTML = '<i class="fas fa-microphone"></i>';
    stopBtn.disabled = true;
    recStatus.textContent = 'บันทึกเสร็จสิ้น';
    recStatus.classList.remove('text-red-400');
    clearInterval(timerInterval);
    cancelAnimationFrame(animationId);
}

function playRecording() {
    if (audioUrl) {
        const audio = new Audio(audioUrl);
        audio.play();
        playBtn.innerHTML = '<i class="fas fa-pause"></i>';
        audio.onended = () => { playBtn.innerHTML = '<i class="fas fa-play"></i>'; };
    }
}

async function saveRecording() {
    if (!audioBlob) return;

    saveBtn.disabled = true;
    saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    recStatus.textContent = 'กำลังบันทึก...';

    try {
        const reader = new FileReader();
        reader.readAsDataURL(audioBlob);
        reader.onload = async () => {
            const base64 = reader.result.split(',')[1];
            const chantSelect = document.getElementById('chant-select');
            const duration = (Date.now() - startTime) / 1000;

            const response = await apiCall('{{ route("record.store") }}', 'POST', {
                audio_data: base64,
                category: document.getElementById('category-select').value,
                chant_name: chantSelect.selectedOptions[0]?.text || 'Recording',
                transcript: document.getElementById('transcript-input').value,
                duration: duration,
            });

            showToast('บันทึกเสียงสำเร็จ!', 'success');
            recStatus.textContent = 'พร้อมบันทึก';

            // Add to recent list
            const list = document.getElementById('recent-list');
            const item = document.createElement('div');
            item.className = 'p-3 rounded-lg bg-temple-50/30 hover:bg-temple-50/50 transition fade-in';
            item.innerHTML = `
                <div class="flex items-center gap-2 mb-1">
                    <i class="fas fa-file-audio text-gold-500/50 text-xs"></i>
                    <span class="text-sm text-gray-300 truncate">${response.original_name}</span>
                </div>
                <div class="flex items-center justify-between text-xs text-gray-600">
                    <span>${formatDuration(duration)}</span>
                    <span>เมื่อสักครู่</span>
                </div>`;
            list.insertBefore(item, list.firstChild);

            // Reset
            audioBlob = null;
            audioUrl = null;
            saveBtn.innerHTML = '<i class="fas fa-save"></i>';
            playBtn.disabled = true;
            saveBtn.disabled = true;
        };
    } catch (err) {
        showToast('เกิดข้อผิดพลาด: ' + err.message, 'error');
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="fas fa-save"></i>';
    }
}

function updateTimer() {
    const elapsed = (Date.now() - startTime) / 1000;
    const min = Math.floor(elapsed / 60);
    const sec = Math.floor(elapsed % 60);
    recTime.textContent = `${String(min).padStart(2,'0')}:${String(sec).padStart(2,'0')}`;
}

function drawVisualizer() {
    if (!analyser) return;

    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;

    function draw() {
        animationId = requestAnimationFrame(draw);
        analyser.getByteTimeDomainData(dataArray);

        ctx.fillStyle = 'rgba(13, 13, 13, 0.3)';
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        ctx.lineWidth = 2;
        ctx.strokeStyle = '#D4A647';
        ctx.beginPath();

        const sliceWidth = WIDTH / bufferLength;
        let x = 0;

        for (let i = 0; i < bufferLength; i++) {
            const v = dataArray[i] / 128.0;
            const y = (v * HEIGHT) / 2;
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
            x += sliceWidth;
        }

        ctx.lineTo(WIDTH, HEIGHT / 2);
        ctx.stroke();

        // Level meter
        let sum = 0;
        for (let i = 0; i < bufferLength; i++) {
            const v = (dataArray[i] - 128) / 128;
            sum += v * v;
        }
        const rms = Math.sqrt(sum / bufferLength);
        const db = Math.max(-60, 20 * Math.log10(rms + 0.0001));
        document.getElementById('level-value').textContent = Math.round(db);
    }

    draw();
}
</script>
@endpush
