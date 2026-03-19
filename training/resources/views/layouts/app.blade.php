<!DOCTYPE html>
<html lang="th" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Aipray AI Training Studio')</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        gold: { 50:'#fdf8e8', 100:'#faefc5', 200:'#f5df8a', 300:'#f0cf50', 400:'#e8bf20', 500:'#D4A647', 600:'#b8860b', 700:'#8b6508', 800:'#5e4406', 900:'#312303' },
                        temple: { 50:'#1a1a2e', 100:'#16162a', 200:'#121226', 300:'#0e0e22', 400:'#0a0a1e', 500:'#0D0D0D', 600:'#080808', 700:'#050505', 800:'#030303', 900:'#010101' }
                    },
                    fontFamily: {
                        thai: ['Noto Sans Thai', 'sans-serif'],
                        inter: ['Inter', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Thai:wght@300;400;500;600;700&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <style>
        * { font-family: 'Noto Sans Thai', 'Inter', sans-serif; }
        body { background: #0D0D0D; }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: #1a1a2e; }
        ::-webkit-scrollbar-thumb { background: #D4A647; border-radius: 3px; }
        .glass { background: rgba(26, 26, 46, 0.8); backdrop-filter: blur(12px); border: 1px solid rgba(212, 166, 71, 0.15); }
        .glow-gold { box-shadow: 0 0 20px rgba(212, 166, 71, 0.15); }
        .gradient-gold { background: linear-gradient(135deg, #D4A647, #b8860b); }
        .gradient-gold-text { background: linear-gradient(135deg, #D4A647, #f0cf50); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .pulse-record { animation: pulseRecord 1.5s ease-in-out infinite; }
        @keyframes pulseRecord { 0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); } 50% { box-shadow: 0 0 0 15px rgba(239, 68, 68, 0); } }
        .sidebar-link.active { background: linear-gradient(135deg, rgba(212,166,71,0.15), rgba(212,166,71,0.05)); border-right: 3px solid #D4A647; }
        .stat-card:hover { transform: translateY(-2px); transition: all 0.3s; }
        .fade-in { animation: fadeIn 0.5s ease-out; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .training-progress-ring { transition: stroke-dashoffset 0.5s ease; }
    </style>
    @stack('styles')
</head>
<body class="bg-temple-500 text-gray-100 min-h-screen font-thai">
    <div class="flex h-screen overflow-hidden">
        <!-- Sidebar -->
        <aside id="sidebar" class="w-64 glass flex-shrink-0 flex flex-col transition-all duration-300 z-30 fixed lg:relative h-full -translate-x-full lg:translate-x-0">
            <!-- Logo -->
            <div class="p-5 border-b border-gold-500/20">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl gradient-gold flex items-center justify-center">
                        <i class="fas fa-om text-white text-lg"></i>
                    </div>
                    <div>
                        <h1 class="text-lg font-bold gradient-gold-text">Aipray AI</h1>
                        <p class="text-xs text-gray-500">Training Studio</p>
                    </div>
                </div>
            </div>

            <!-- Navigation -->
            <nav class="flex-1 p-3 space-y-1 overflow-y-auto">
                <a href="{{ route('dashboard') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('dashboard') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-chart-line w-5 text-center"></i>
                    <span>แดชบอร์ด</span>
                </a>
                <a href="{{ route('dataset.index') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('dataset.*') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-database w-5 text-center"></i>
                    <span>ชุดข้อมูลเสียง</span>
                </a>
                <a href="{{ route('record.index') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('record.*') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-microphone w-5 text-center"></i>
                    <span>บันทึกเสียง</span>
                </a>
                <a href="{{ route('training.index') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('training.*') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-brain w-5 text-center"></i>
                    <span>เทรนโมเดล</span>
                </a>
                <a href="{{ route('evaluate.index') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('evaluate.*') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-flask w-5 text-center"></i>
                    <span>ทดสอบ & ประเมิน</span>
                </a>
                <a href="{{ route('models.index') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-lg text-sm transition-all hover:bg-gold-500/10 {{ request()->routeIs('models.*') ? 'active text-gold-400' : 'text-gray-400' }}">
                    <i class="fas fa-cubes w-5 text-center"></i>
                    <span>จัดการโมเดล</span>
                </a>
            </nav>

            <!-- Footer -->
            <div class="p-4 border-t border-gold-500/20">
                <div class="flex items-center gap-2 text-xs text-gray-500">
                    <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
                    <span>ระบบพร้อมใช้งาน</span>
                </div>
            </div>
        </aside>

        <!-- Overlay for mobile -->
        <div id="sidebar-overlay" class="fixed inset-0 bg-black/50 z-20 hidden lg:hidden" onclick="toggleSidebar()"></div>

        <!-- Main Content -->
        <div class="flex-1 flex flex-col overflow-hidden">
            <!-- Top Bar -->
            <header class="glass border-b border-gold-500/10 px-6 py-3 flex items-center justify-between flex-shrink-0">
                <div class="flex items-center gap-4">
                    <button onclick="toggleSidebar()" class="lg:hidden text-gray-400 hover:text-gold-400 transition">
                        <i class="fas fa-bars text-xl"></i>
                    </button>
                    <h2 class="text-lg font-semibold text-gray-200">@yield('page-title', 'แดชบอร์ด')</h2>
                </div>
                <div class="flex items-center gap-3">
                    <div class="relative hidden md:block">
                        <i class="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm"></i>
                        <input type="text" placeholder="ค้นหา..." class="bg-temple-50/50 border border-gold-500/10 rounded-lg pl-9 pr-4 py-2 text-sm text-gray-300 focus:outline-none focus:border-gold-500/30 w-48 lg:w-64">
                    </div>
                    <button class="relative text-gray-400 hover:text-gold-400 transition p-2">
                        <i class="fas fa-bell"></i>
                        <span class="absolute -top-0.5 -right-0.5 w-4 h-4 bg-red-500 rounded-full text-[10px] flex items-center justify-center text-white">3</span>
                    </button>
                </div>
            </header>

            <!-- Page Content -->
            <main class="flex-1 overflow-y-auto p-6">
                <!-- Flash Messages -->
                @if(session('success'))
                <div class="mb-4 p-4 rounded-lg bg-green-500/10 border border-green-500/30 text-green-400 flex items-center gap-2 fade-in">
                    <i class="fas fa-check-circle"></i>
                    <span>{{ session('success') }}</span>
                </div>
                @endif

                @if(session('error'))
                <div class="mb-4 p-4 rounded-lg bg-red-500/10 border border-red-500/30 text-red-400 flex items-center gap-2 fade-in">
                    <i class="fas fa-exclamation-circle"></i>
                    <span>{{ session('error') }}</span>
                </div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>

    <!-- Toast Container -->
    <div id="toast-container" class="fixed bottom-4 right-4 z-50 space-y-2"></div>

    <script>
        // CSRF Token for AJAX
        window.csrfToken = '{{ csrf_token() }}';

        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('sidebar-overlay');
            sidebar.classList.toggle('-translate-x-full');
            overlay.classList.toggle('hidden');
        }

        function showToast(message, type = 'success') {
            const container = document.getElementById('toast-container');
            const colors = {
                success: 'bg-green-500/20 border-green-500/50 text-green-400',
                error: 'bg-red-500/20 border-red-500/50 text-red-400',
                info: 'bg-blue-500/20 border-blue-500/50 text-blue-400',
                warning: 'bg-yellow-500/20 border-yellow-500/50 text-yellow-400',
            };
            const icons = { success: 'check-circle', error: 'exclamation-circle', info: 'info-circle', warning: 'exclamation-triangle' };

            const toast = document.createElement('div');
            toast.className = `p-4 rounded-lg border ${colors[type]} flex items-center gap-2 fade-in backdrop-blur-lg min-w-[300px]`;
            const icon = document.createElement('i');
            icon.className = `fas fa-${icons[type]}`;
            const span = document.createElement('span');
            span.textContent = message;
            toast.appendChild(icon);
            toast.appendChild(span);
            container.appendChild(toast);

            setTimeout(() => { toast.style.opacity = '0'; toast.style.transition = 'opacity 0.5s'; setTimeout(() => toast.remove(), 500); }, 4000);
        }

        async function apiCall(url, method = 'GET', data = null) {
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': window.csrfToken,
                },
            };
            if (data) options.body = JSON.stringify(data);
            const response = await fetch(url, options);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return response.json();
        }

        function formatNumber(n) {
            return new Intl.NumberFormat('th-TH').format(n);
        }

        function formatDuration(seconds) {
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);
            if (h > 0) return `${h}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
            return `${m}:${String(s).padStart(2,'0')}`;
        }
    </script>
    @stack('scripts')
</body>
</html>
