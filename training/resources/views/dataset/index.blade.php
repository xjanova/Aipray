@extends('layouts.app')
@section('title', 'ชุดข้อมูลเสียง - Aipray AI')
@section('page-title', 'ชุดข้อมูลเสียง')

@section('content')
<!-- Stats -->
<div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
    <div class="glass rounded-lg p-4 text-center">
        <p class="text-2xl font-bold text-gray-100">{{ number_format($stats['total']) }}</p>
        <p class="text-xs text-gray-500 mt-1">ทั้งหมด</p>
    </div>
    <div class="glass rounded-lg p-4 text-center">
        <p class="text-2xl font-bold text-blue-400">{{ number_format($stats['labeled']) }}</p>
        <p class="text-xs text-gray-500 mt-1">ติดป้ายแล้ว</p>
    </div>
    <div class="glass rounded-lg p-4 text-center">
        <p class="text-2xl font-bold text-yellow-400">{{ number_format($stats['unlabeled']) }}</p>
        <p class="text-xs text-gray-500 mt-1">ยังไม่ติดป้าย</p>
    </div>
    <div class="glass rounded-lg p-4 text-center">
        <p class="text-2xl font-bold text-green-400">{{ $stats['totalDuration'] }}h</p>
        <p class="text-xs text-gray-500 mt-1">ความยาวรวม</p>
    </div>
</div>

<!-- Toolbar -->
<div class="glass rounded-xl p-4 mb-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
    <div class="flex flex-wrap gap-2">
        <form method="GET" action="{{ route('dataset.index') }}" class="flex gap-2" id="filter-form">
            <select name="category" class="bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" onchange="this.form.submit()">
                <option value="all" {{ request('category') == 'all' ? 'selected' : '' }}>ทุกหมวดหมู่</option>
                <option value="daily" {{ request('category') == 'daily' ? 'selected' : '' }}>บทสวดประจำวัน</option>
                <option value="protection" {{ request('category') == 'protection' ? 'selected' : '' }}>บทป้องกัน</option>
                <option value="meditation" {{ request('category') == 'meditation' ? 'selected' : '' }}>บทสมาธิ</option>
                <option value="merit" {{ request('category') == 'merit' ? 'selected' : '' }}>บทแผ่เมตตา</option>
                <option value="sutra" {{ request('category') == 'sutra' ? 'selected' : '' }}>พระสูตร</option>
            </select>
            <select name="status" class="bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" onchange="this.form.submit()">
                <option value="all" {{ request('status') == 'all' ? 'selected' : '' }}>ทุกสถานะ</option>
                <option value="labeled" {{ request('status') == 'labeled' ? 'selected' : '' }}>ติดป้ายแล้ว</option>
                <option value="unlabeled" {{ request('status') == 'unlabeled' ? 'selected' : '' }}>ยังไม่ติดป้าย</option>
                <option value="verified" {{ request('status') == 'verified' ? 'selected' : '' }}>ตรวจสอบแล้ว</option>
            </select>
        </form>
    </div>
    <div class="flex gap-2">
        <button onclick="document.getElementById('upload-modal').classList.remove('hidden')" class="px-4 py-2 gradient-gold rounded-lg text-sm font-medium text-white hover:opacity-90 transition">
            <i class="fas fa-plus mr-1"></i> เพิ่มข้อมูล
        </button>
    </div>
</div>

<!-- Data Table -->
<div class="glass rounded-xl overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full">
            <thead>
                <tr class="border-b border-gold-500/10">
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                        <input type="checkbox" id="select-all" class="rounded border-gray-600">
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">ไฟล์</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">หมวดหมู่</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">ป้ายกำกับ</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">ความยาว</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">สถานะ</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">วันที่</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">จัดการ</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gold-500/5">
                @forelse($samples as $sample)
                <tr class="hover:bg-gold-500/5 transition">
                    <td class="px-4 py-3"><input type="checkbox" value="{{ $sample->id }}" class="sample-checkbox rounded border-gray-600"></td>
                    <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                            <i class="fas fa-file-audio text-gold-500"></i>
                            <span class="text-sm text-gray-300">{{ Str::limit($sample->original_name, 30) }}</span>
                        </div>
                    </td>
                    <td class="px-4 py-3">
                        @php $catLabels = ['daily'=>'ประจำวัน','protection'=>'ป้องกัน','meditation'=>'สมาธิ','merit'=>'แผ่เมตตา','sutra'=>'พระสูตร']; @endphp
                        <span class="text-xs px-2 py-1 rounded-full bg-gold-500/10 text-gold-400">{{ $catLabels[$sample->category] ?? $sample->category }}</span>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-400">{{ Str::limit($sample->label ?? '-', 20) }}</td>
                    <td class="px-4 py-3 text-sm text-gray-400">{{ $sample->duration_formatted }}</td>
                    <td class="px-4 py-3">
                        <span class="text-xs px-2 py-1 rounded-full
                            {{ $sample->status === 'verified' ? 'bg-green-500/20 text-green-400' :
                               ($sample->status === 'labeled' ? 'bg-blue-500/20 text-blue-400' :
                               ($sample->status === 'rejected' ? 'bg-red-500/20 text-red-400' : 'bg-gray-500/20 text-gray-400')) }}">
                            {{ $sample->status }}
                        </span>
                    </td>
                    <td class="px-4 py-3 text-xs text-gray-500">{{ $sample->created_at->format('d/m/Y') }}</td>
                    <td class="px-4 py-3">
                        <div class="flex gap-1">
                            <button onclick="editSample({{ $sample->id }})" class="p-1.5 rounded hover:bg-gold-500/10 text-gray-400 hover:text-gold-400 transition" title="แก้ไข">
                                <i class="fas fa-edit text-xs"></i>
                            </button>
                            <form method="POST" action="{{ route('dataset.destroy', $sample) }}" onsubmit="return confirm('ยืนยันการลบ?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="p-1.5 rounded hover:bg-red-500/10 text-gray-400 hover:text-red-400 transition" title="ลบ">
                                    <i class="fas fa-trash text-xs"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="8" class="px-4 py-12 text-center text-gray-600">
                        <i class="fas fa-database text-4xl mb-3"></i>
                        <p class="text-lg">ยังไม่มีข้อมูลเสียง</p>
                        <p class="text-sm mt-1">เริ่มบันทึกเสียงเพื่อสร้างชุดข้อมูล</p>
                        <a href="{{ route('record.index') }}" class="inline-block mt-3 px-4 py-2 gradient-gold rounded-lg text-sm text-white hover:opacity-90 transition">
                            <i class="fas fa-microphone mr-1"></i> บันทึกเสียง
                        </a>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($samples->hasPages())
    <div class="p-4 border-t border-gold-500/10">
        {{ $samples->links() }}
    </div>
    @endif
</div>

<!-- Upload Modal -->
<div id="upload-modal" class="fixed inset-0 z-50 hidden flex items-center justify-center bg-black/60 backdrop-blur-sm">
    <div class="glass rounded-2xl p-6 w-full max-w-lg mx-4">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-200"><i class="fas fa-cloud-upload-alt text-gold-500 mr-2"></i>อัปโหลดเสียง</h3>
            <button onclick="document.getElementById('upload-modal').classList.add('hidden')" class="text-gray-500 hover:text-gray-300"><i class="fas fa-times"></i></button>
        </div>
        <form method="POST" action="{{ route('dataset.store') }}" enctype="multipart/form-data">
            @csrf
            <div class="space-y-4">
                <div>
                    <label class="block text-sm text-gray-400 mb-1">ไฟล์เสียง</label>
                    <div class="border-2 border-dashed border-gold-500/20 rounded-xl p-6 text-center hover:border-gold-500/40 transition cursor-pointer" onclick="document.getElementById('audio-file').click()">
                        <i class="fas fa-cloud-upload-alt text-3xl text-gold-500/50 mb-2"></i>
                        <p class="text-sm text-gray-400">ลากไฟล์มาวางหรือคลิกเพื่อเลือก</p>
                        <p class="text-xs text-gray-600 mt-1">.wav, .mp3, .ogg (สูงสุด 50MB)</p>
                        <input type="file" name="audio" id="audio-file" accept="audio/*" class="hidden" required>
                    </div>
                    <p id="file-name" class="text-xs text-gold-400 mt-1 hidden"></p>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">หมวดหมู่</label>
                    <select name="category" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" required>
                        <option value="daily">บทสวดประจำวัน</option>
                        <option value="protection">บทป้องกัน</option>
                        <option value="meditation">บทสมาธิ</option>
                        <option value="merit">บทแผ่เมตตา</option>
                        <option value="sutra">พระสูตร</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">ป้ายกำกับ (Label)</label>
                    <input type="text" name="label" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="เช่น นะโม ตัสสะ">
                </div>
                <div>
                    <label class="block text-sm text-gray-400 mb-1">คำถอดเสียง (Transcript)</label>
                    <textarea name="transcript" rows="3" class="w-full bg-temple-50/50 border border-gold-500/10 rounded-lg px-3 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30" placeholder="ข้อความในเสียง..."></textarea>
                </div>
            </div>
            <div class="flex gap-3 mt-6">
                <button type="submit" class="flex-1 py-2.5 gradient-gold rounded-lg text-sm font-medium text-white hover:opacity-90 transition">
                    <i class="fas fa-upload mr-1"></i> อัปโหลด
                </button>
                <button type="button" onclick="document.getElementById('upload-modal').classList.add('hidden')" class="px-4 py-2.5 bg-gray-700/50 rounded-lg text-sm text-gray-400 hover:bg-gray-700 transition">ยกเลิก</button>
            </div>
        </form>
    </div>
</div>
@endsection

@push('scripts')
<script>
document.getElementById('audio-file')?.addEventListener('change', function(e) {
    const name = e.target.files[0]?.name;
    if (name) {
        const el = document.getElementById('file-name');
        el.textContent = '📁 ' + name;
        el.classList.remove('hidden');
    }
});

function editSample(id) {
    showToast('เปิดหน้าแก้ไข...', 'info');
    window.location.href = `/dataset/${id}`;
}
</script>
@endpush
