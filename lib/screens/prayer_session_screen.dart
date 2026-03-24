import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../main.dart';
import '../models/chant.dart';
import '../models/prayer_session.dart';
import '../services/audio_service.dart';
import '../services/chant_matcher.dart';
import '../services/recording_service.dart';

class PrayerSessionScreen extends StatefulWidget {
  final Chant chant;
  final bool voiceMode;
  final bool simulationMode;

  const PrayerSessionScreen({
    super.key,
    required this.chant,
    this.voiceMode = false,
    this.simulationMode = false,
  });

  @override
  State<PrayerSessionScreen> createState() => _PrayerSessionScreenState();
}

class _PrayerSessionScreenState extends State<PrayerSessionScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _matcher = ChantMatcher();
  final _audioService = AudioService();
  final _recordingService = RecordingService();
  final _sessionId = const Uuid().v4();
  bool _isContributing = false;

  int _currentLine = -1;
  int _rounds = 0;
  bool _autoScroll = true;
  bool _isListening = false;
  String _statusText = 'พร้อม';
  String _lastTranscript = '';
  double _confidence = 0;
  late DateTime _startTime;
  Timer? _timerTick;
  Timer? _simulationTimer;
  String _elapsed = '00:00';
  late AnimationController _pulseController;

  // Track consecutive transcripts for better matching
  final List<String> _recentTranscripts = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _matcher.buildIndex([widget.chant]);
    _matcher.setActiveChant(widget.chant.id);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = DateTime.now().difference(_startTime);
      setState(() {
        _elapsed =
            '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });

    // Check if user opted into AI data contribution
    _isContributing =
        storageService.getSetting<bool>('contributeData') ?? false;
    if (_isContributing) {
      _recordingService.init();
    }

    // Set up audio service callbacks
    _audioService.onTranscript = _onTranscript;
    _audioService.onStatusChange = _onAudioStatusChange;

    if (widget.simulationMode) {
      _startSimulation();
    } else if (widget.voiceMode) {
      // Auto-start voice recognition
      _initAndStartListening();
    }
  }

  @override
  void dispose() {
    _timerTick?.cancel();
    _simulationTimer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    _audioService.dispose();
    _recordingService.dispose();
    _saveSession();
    super.dispose();
  }

  // === Audio Recognition ===

  Future<void> _initAndStartListening() async {
    setState(() => _statusText = 'กำลังเตรียมไมโครโฟน...');

    final ok = await _audioService.initialize();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _statusText = 'ไม่สามารถใช้ไมโครโฟนได้: ${_audioService.lastError}';
      });
      _showMicPermissionDialog();
      return;
    }

    _startVoiceListening();
  }

  Future<void> _startVoiceListening() async {
    await _audioService.startListening();
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _statusText = 'กำลังฟังเสียงสวด...';
    });
  }

  Future<void> _stopVoiceListening() async {
    await _audioService.stopListening();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _statusText = 'หยุดฟังแล้ว';
    });
  }

  void _toggleVoiceListening() {
    if (_isListening) {
      _stopVoiceListening();
    } else {
      if (_audioService.isAvailable) {
        _startVoiceListening();
      } else {
        _initAndStartListening();
      }
    }
  }

  void _onTranscript(String transcript, bool isFinal) {
    if (!mounted) return;

    setState(() {
      _lastTranscript = transcript;
    });

    // Add to recent for context window
    if (isFinal && transcript.isNotEmpty) {
      _recentTranscripts.add(transcript);
      if (_recentTranscripts.length > 5) {
        _recentTranscripts.removeAt(0);
      }
    }

    // Try matching against the transcript
    _processTranscript(transcript);
  }

  void _onAudioStatusChange(AudioServiceStatus status) {
    if (!mounted) return;
    switch (status) {
      case AudioServiceStatus.listening:
        setState(() => _statusText = 'กำลังฟังเสียงสวด...');
      case AudioServiceStatus.error:
        setState(
            () => _statusText = 'ข้อผิดพลาด: ${_audioService.lastError}');
      case AudioServiceStatus.notAvailable:
        setState(() => _statusText = 'ไม่รองรับการฟังเสียงบนอุปกรณ์นี้');
      case AudioServiceStatus.idle:
        if (!_isListening) setState(() => _statusText = 'พร้อม');
      default:
        break;
    }
  }

  void _processTranscript(String transcript) {
    final match = _matcher.findMatch(transcript);

    if (match == null) {
      // Try combining recent transcripts for longer context
      if (_recentTranscripts.length >= 2) {
        final combined = _recentTranscripts.join(' ');
        final combinedMatch = _matcher.findMatch(combined);
        if (combinedMatch != null) {
          _applyMatch(combinedMatch);
          return;
        }
      }
      setState(() => _statusText = 'กำลังจับตำแหน่ง...');
      return;
    }

    _applyMatch(match);
  }

  void _applyMatch(MatchResult match) {
    setState(() {
      _confidence = match.confidence;
      _statusText = match.confidence >= 0.7
          ? 'จับตำแหน่งได้ชัดเจน'
          : 'จับตำแหน่งได้ (ความมั่นใจต่ำ)';
    });
    _goToLine(match.lineIndex);
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('ต้องการสิทธิ์ไมโครโฟน',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'แอพต้องการใช้ไมโครโฟนเพื่อฟังเสียงสวดมนต์และจับตำแหน่งอัตโนมัติ\n\n'
          'กรุณาอนุญาตการใช้ไมโครโฟนในการตั้งค่าของอุปกรณ์',
          style: TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _initAndStartListening();
            },
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }

  // === Session Management ===

  void _saveSession() {
    // Stop any active recording
    if (_recordingService.isRecording) {
      _recordingService.stopAndUpload();
    }

    final session = PrayerSession(
      id: _sessionId,
      chantId: widget.chant.id,
      chantTitle: widget.chant.title,
      startTime: _startTime,
      endTime: DateTime.now(),
      roundsCompleted: _rounds,
      totalLines: widget.chant.lineCount,
      linesReached: _currentLine + 1,
      usedVoiceTracking: widget.voiceMode || widget.simulationMode,
    );

    // Save locally
    storageService.saveSession(session);

    // Upload to backend (async, with offline queue)
    syncService.uploadSession(session);
  }

  void _goToLine(int index, {bool fromNextLine = false}) {
    if (index < 0 || index >= widget.chant.lineCount) return;

    // Stop recording previous segment and upload
    if (_isContributing && _recordingService.isRecording) {
      _recordingService.stopAndUpload();
    }

    // Check if completed a round (only if NOT called from _nextLine to avoid double count)
    if (!fromNextLine && index == 0 && _currentLine == widget.chant.lineCount - 1) {
      _rounds++;
      HapticFeedback.heavyImpact();
      _showRoundCompleteOverlay();
    }

    setState(() {
      _currentLine = index;
    });

    // Start recording new segment for AI training
    if (_isContributing && _isListening) {
      _recordingService.startSegment(
        chantId: widget.chant.id,
        lineIndex: index,
      );
    }

    if (_autoScroll) {
      _scrollToLine(index);
    }
  }

  void _scrollToLine(int index) {
    final targetOffset = index * 72.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextLine() {
    final next = (_currentLine + 1) % widget.chant.lineCount;
    if (_currentLine >= 0 && next == 0) {
      _rounds++;
      HapticFeedback.heavyImpact();
      _showRoundCompleteOverlay();
    }
    _goToLine(next, fromNextLine: true);
  }

  void _prevLine() {
    if (_currentLine > 0) {
      _goToLine(_currentLine - 1);
    }
  }

  void _showRoundCompleteOverlay() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              'สวดครบรอบที่ $_rounds',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A3D2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // === Simulation ===

  void _startSimulation() {
    setState(() {
      _statusText = 'โหมดจำลองกำลังทำงาน';
      _isListening = true;
    });

    int pointer = 0;
    _simulationTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      if (pointer >= widget.chant.lineCount) {
        _rounds++;
        pointer = 0;
        HapticFeedback.heavyImpact();
        _showRoundCompleteOverlay();
      }

      setState(() {
        _lastTranscript = widget.chant.lines[pointer].text;
        _confidence = 1.0;
        _statusText = 'จับตำแหน่งได้';
      });
      _goToLine(pointer, fromNextLine: true);
      pointer++;
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isListening = false;
      _statusText = 'หยุดจำลอง';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(widget.chant.title, style: const TextStyle(fontSize: 16)),
        actions: [
          // Round counter
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AiprayTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.loop, size: 16, color: AiprayTheme.gold),
                const SizedBox(width: 4),
                Text('$_rounds',
                    style: TextStyle(
                        color: AiprayTheme.gold, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_elapsed,
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          _StatusBar(
            status: _statusText,
            transcript: _lastTranscript,
            confidence: _confidence,
            isListening: _isListening,
            pulseAnimation: _pulseController,
          ),

          // Progress indicator
          if (_currentLine >= 0)
            LinearProgressIndicator(
              value: (_currentLine + 1) / widget.chant.lineCount,
              backgroundColor: const Color(0xFF333333),
              valueColor: AlwaysStoppedAnimation(
                  AiprayTheme.gold.withValues(alpha: 0.6)),
              minHeight: 3,
            ),

          // Lines
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.chant.lineCount,
              itemBuilder: (context, i) {
                final line = widget.chant.lines[i];
                final isActive = i == _currentLine;
                final isNext = i == _currentLine + 1;
                final isPast = i < _currentLine && _currentLine >= 0;

                return GestureDetector(
                  onTap: () => _goToLine(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AiprayTheme.activeLineColor
                          : isNext
                              ? AiprayTheme.nextLineColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(
                              color: AiprayTheme.gold.withValues(alpha: 0.5),
                              width: 1.5)
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30,
                          child: isPast
                              ? Icon(Icons.check,
                                  size: 16,
                                  color:
                                      const Color(0xFF10B981).withValues(alpha: 0.5))
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? AiprayTheme.gold
                                        : const Color(0xFF555555),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Text(
                            line.text,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : isNext
                                      ? Colors.white70
                                      : isPast
                                          ? const Color(0xFF888888)
                                          : const Color(0xFFCCCCCC),
                              fontSize: isActive ? 20 : 18,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.7,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.volume_up,
                              color: AiprayTheme.gold.withValues(alpha: 0.6),
                              size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom controls
          _BottomControls(
            isListening: _isListening,
            isSimulation: widget.simulationMode,
            isVoiceMode: widget.voiceMode,
            autoScroll: _autoScroll,
            onToggleListen: widget.simulationMode
                ? () {
                    if (_isListening) {
                      _stopSimulation();
                    } else {
                      _startSimulation();
                    }
                  }
                : widget.voiceMode
                    ? _toggleVoiceListening
                    : null,
            onPrev: _prevLine,
            onNext: _nextLine,
            onToggleAutoScroll: () =>
                setState(() => _autoScroll = !_autoScroll),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String status;
  final String transcript;
  final double confidence;
  final bool isListening;
  final AnimationController pulseAnimation;

  const _StatusBar({
    required this.status,
    required this.transcript,
    required this.confidence,
    required this.isListening,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          if (isListening)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      Colors.red,
                      Colors.red.withValues(alpha: 0.3),
                      pulseAnimation.value,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF555555),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: isListening
                        ? const Color(0xFF10B981)
                        : const Color(0xFFA09880),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transcript.isNotEmpty)
                  Text(
                    transcript,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (confidence > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: confidence > 0.7
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  color: confidence > 0.7
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool isListening;
  final bool isSimulation;
  final bool isVoiceMode;
  final bool autoScroll;
  final VoidCallback? onToggleListen;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggleAutoScroll;

  const _BottomControls({
    required this.isListening,
    required this.isSimulation,
    required this.isVoiceMode,
    required this.autoScroll,
    this.onToggleListen,
    required this.onPrev,
    required this.onNext,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Auto scroll toggle
            IconButton(
              onPressed: onToggleAutoScroll,
              icon: Icon(
                autoScroll ? Icons.swap_vert : Icons.swap_vert,
                color: autoScroll ? AiprayTheme.gold : const Color(0xFF555555),
              ),
              tooltip: autoScroll ? 'ปิดเลื่อนอัตโนมัติ' : 'เปิดเลื่อนอัตโนมัติ',
            ),

            // Prev
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.skip_previous, color: Colors.white70),
              iconSize: 32,
            ),

            // Main action button
            GestureDetector(
              onTap: onToggleListen ??
                  () {
                    // For read mode, just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ใช้ปุ่ม ◀ ▶ เลื่อนบรรทัด หรือแตะที่บรรทัดโดยตรง'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? Colors.red
                      : isVoiceMode || isSimulation
                          ? AiprayTheme.gold
                          : const Color(0xFF333333),
                  boxShadow: isVoiceMode || isSimulation
                      ? [
                          BoxShadow(
                            color:
                                (isListening ? Colors.red : AiprayTheme.gold)
                                    .withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isListening
                      ? Icons.stop
                      : isSimulation
                          ? Icons.play_arrow
                          : isVoiceMode
                              ? Icons.mic
                              : Icons.touch_app,
                  color: isListening || isVoiceMode || isSimulation
                      ? (isListening ? Colors.white : const Color(0xFF0D0D0D))
                      : const Color(0xFF888888),
                  size: 30,
                ),
              ),
            ),

            // Next
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.skip_next, color: Colors.white70),
              iconSize: 32,
            ),

            // Reset / info
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF242424),
                    title: const Text('วิธีใช้',
                        style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _helpRow(Icons.mic, 'กดปุ่มกลางเพื่อเริ่ม/หยุดฟังเสียง'),
                        const SizedBox(height: 8),
                        _helpRow(Icons.touch_app, 'แตะบรรทัดเพื่อข้ามไปตำแหน่งนั้น'),
                        const SizedBox(height: 8),
                        _helpRow(Icons.skip_next, 'ใช้ปุ่ม ◀ ▶ เลื่อนบรรทัด'),
                        const SizedBox(height: 8),
                        _helpRow(Icons.swap_vert, 'เปิด/ปิดเลื่อนอัตโนมัติ'),
                        const SizedBox(height: 8),
                        _helpRow(Icons.loop, 'นับรอบอัตโนมัติเมื่อสวดครบ'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('เข้าใจแล้ว'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _helpRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AiprayTheme.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
        ),
      ],
    );
  }
}
