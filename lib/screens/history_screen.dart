import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../main.dart';
import '../models/prayer_session.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PrayerSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = storageService.getSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ประวัติการสวดมนต์',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AiprayTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'รวม ${_sessions.length} ครั้ง',
                  style: const TextStyle(color: Color(0xFFA09880)),
                ),
              ],
            ),
          ),

          // Stats summary
          if (_sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _SummaryCard(sessions: _sessions),
            ),

          Expanded(
            child: _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.self_improvement,
                          size: 64,
                          color: AiprayTheme.gold.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ยังไม่มีประวัติ',
                          style: TextStyle(
                            color: Color(0xFFA09880),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'เริ่มสวดมนต์เพื่อบันทึกประวัติ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadSessions(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _sessions.length,
                      itemBuilder: (context, i) =>
                          _SessionTile(session: _sessions[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<PrayerSession> sessions;
  const _SummaryCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalRounds = sessions.fold(0, (s, e) => s + e.roundsCompleted);
    final totalDuration = sessions.fold(
      Duration.zero,
      (s, e) => s + e.duration,
    );
    final streak = _calculateStreak(sessions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AiprayTheme.gold.withValues(alpha: 0.12),
            AiprayTheme.gold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiprayTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            icon: Icons.loop,
            value: '$totalRounds',
            label: 'รอบทั้งหมด',
          ),
          _MiniStat(
            icon: Icons.timer,
            value: _formatDuration(totalDuration),
            label: 'เวลารวม',
          ),
          _MiniStat(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: 'วันติดต่อกัน',
          ),
        ],
      ),
    );
  }

  static int _calculateStreak(List<PrayerSession> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i - 1].difference(dates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AiprayTheme.gold, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA09880), fontSize: 11),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final PrayerSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AiprayTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.usedVoiceTracking ? Icons.mic : Icons.auto_stories,
                color: AiprayTheme.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.chantTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(session.startTime),
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.durationFormatted,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (session.roundsCompleted > 0)
                  Text(
                    '${session.roundsCompleted} รอบ',
                    style: TextStyle(
                      color: AiprayTheme.gold.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
