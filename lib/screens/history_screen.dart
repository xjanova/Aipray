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

          Expanded(
            child: _sessions.isEmpty
                ? _EmptyState()
                : RefreshIndicator(
                    onRefresh: () async => _loadSessions(),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Summary card
                        _SummaryCard(sessions: _sessions),
                        const SizedBox(height: 16),

                        // Weekly heatmap
                        _WeeklyHeatmap(sessions: _sessions),
                        const SizedBox(height: 16),

                        // AI Insights
                        _InsightsCard(sessions: _sessions),
                        const SizedBox(height: 16),

                        // Top chants
                        _TopChantsCard(sessions: _sessions),
                        const SizedBox(height: 16),

                        // Session list header
                        Row(
                          children: [
                            const Icon(Icons.history, color: Color(0xFFA09880), size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'รายการทั้งหมด',
                              style: TextStyle(
                                color: Color(0xFFA09880),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Session tiles
                        ...List.generate(
                          _sessions.length,
                          (i) => _SessionTile(session: _sessions[i]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.self_improvement, size: 64,
              color: AiprayTheme.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('ยังไม่มีประวัติ',
              style: TextStyle(color: Color(0xFFA09880), fontSize: 16)),
          const SizedBox(height: 4),
          const Text('เริ่มสวดมนต์เพื่อบันทึกประวัติ',
              style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
        ],
      ),
    );
  }
}

// === Weekly Activity Heatmap ===
class _WeeklyHeatmap extends StatelessWidget {
  final List<PrayerSession> sessions;
  const _WeeklyHeatmap({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = 8; // Show 8 weeks
    final days = <DateTime, int>{};

    for (final s in sessions) {
      final day = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      days[day] = (days[day] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AiprayTheme.gold, size: 16),
              const SizedBox(width: 8),
              const Text('กิจกรรม 8 สัปดาห์',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Day labels
          Row(
            children: [
              const SizedBox(width: 28),
              ...['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'].map((d) => Expanded(
                child: Center(
                  child: Text(d, style: const TextStyle(color: Color(0xFF666666), fontSize: 9)),
                ),
              )),
            ],
          ),
          const SizedBox(height: 4),
          // Heatmap grid
          ...List.generate(weeks, (weekIdx) {
            final weekStart = now.subtract(Duration(days: now.weekday - 1 + (weeks - 1 - weekIdx) * 7));
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      'W${weekIdx + 1}',
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 8),
                    ),
                  ),
                  ...List.generate(7, (dayIdx) {
                    final date = weekStart.add(Duration(days: dayIdx));
                    final dateKey = DateTime(date.year, date.month, date.day);
                    final count = days[dateKey] ?? 0;
                    final isToday = dateKey == DateTime(now.year, now.month, now.day);
                    final isFuture = date.isAfter(now);

                    Color cellColor;
                    if (isFuture) {
                      cellColor = const Color(0xFF1A1A1A);
                    } else if (count == 0) {
                      cellColor = const Color(0xFF242424);
                    } else if (count == 1) {
                      cellColor = AiprayTheme.gold.withValues(alpha: 0.3);
                    } else if (count <= 3) {
                      cellColor = AiprayTheme.gold.withValues(alpha: 0.6);
                    } else {
                      cellColor = AiprayTheme.gold;
                    }

                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(3),
                            border: isToday
                                ? Border.all(color: Colors.white, width: 1.5)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('น้อย', style: TextStyle(color: Color(0xFF666666), fontSize: 9)),
              const SizedBox(width: 4),
              ...([0.0, 0.3, 0.6, 1.0]).map((alpha) => Container(
                width: 12, height: 12, margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: alpha == 0.0
                      ? const Color(0xFF242424)
                      : AiprayTheme.gold.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(width: 4),
              const Text('มาก', style: TextStyle(color: Color(0xFF666666), fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// === AI Insights Card ===
class _InsightsCard extends StatelessWidget {
  final List<PrayerSession> sessions;
  const _InsightsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();
    if (insights.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AiprayTheme.gold, size: 16),
              const SizedBox(width: 8),
              const Text('AI วิเคราะห์',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AiprayTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('SMART', style: TextStyle(color: AiprayTheme.gold, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(insight.text,
                      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<_Insight> _generateInsights() {
    if (sessions.isEmpty) return [];
    final insights = <_Insight>[];

    // Best time analysis
    final hourCounts = <int, int>{};
    for (final s in sessions) {
      final h = s.startTime.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    if (hourCounts.isNotEmpty) {
      final bestHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final period = bestHour < 12 ? 'เช้า' : bestHour < 17 ? 'บ่าย' : 'เย็น';
      insights.add(_Insight('⏰', 'คุณสวดมนต์บ่อยที่สุดช่วง$period (~$bestHour:00 น.)'));
    }

    // Average duration
    final avgDuration = sessions.fold(Duration.zero, (s, e) => s + e.duration) ~/ sessions.length;
    if (avgDuration.inMinutes > 0) {
      insights.add(_Insight('📊', 'เวลาสวดเฉลี่ย ${avgDuration.inMinutes} นาทีต่อครั้ง'));
    }

    // Voice vs manual
    final voiceCount = sessions.where((s) => s.usedVoiceTracking).length;
    final pct = (voiceCount / sessions.length * 100).round();
    if (pct > 0) {
      insights.add(_Insight('🎤', 'ใช้โหมด AI ฟังเสียง $pct% ของทั้งหมด'));
    }

    // Streak motivation
    final dates = sessions.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!dates.contains(today)) {
      insights.add(_Insight('🔥', 'วันนี้ยังไม่ได้สวดมนต์ สวดวันนี้เพื่อรักษา streak!'));
    }

    return insights.take(4).toList();
  }
}

class _Insight {
  final String emoji;
  final String text;
  _Insight(this.emoji, this.text);
}

// === Top Chants Card ===
class _TopChantsCard extends StatelessWidget {
  final List<PrayerSession> sessions;
  const _TopChantsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.chantTitle] = (counts[s.chantTitle] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox();

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxCount = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AiprayTheme.gold, size: 16),
              const SizedBox(width: 8),
              const Text('บทสวดยอดนิยม',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final ratio = entry.value / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: idx == 0 ? AiprayTheme.gold : const Color(0xFF888888),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(entry.key,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${entry.value} ครั้ง',
                          style: TextStyle(color: AiprayTheme.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF333333),
                      valueColor: AlwaysStoppedAnimation(
                        idx == 0 ? AiprayTheme.gold : AiprayTheme.gold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
    final totalDuration = sessions.fold(Duration.zero, (s, e) => s + e.duration);
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
          _MiniStat(icon: Icons.loop, value: '$totalRounds', label: 'รอบทั้งหมด'),
          _MiniStat(icon: Icons.timer, value: _formatDuration(totalDuration), label: 'เวลารวม'),
          _MiniStat(icon: Icons.local_fire_department, value: '$streak', label: 'วันติดต่อกัน'),
        ],
      ),
    );
  }

  static int _calculateStreak(List<PrayerSession> sessions) {
    if (sessions.isEmpty) return 0;
    final dates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet().toList()..sort((a, b) => b.compareTo(a));
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
  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AiprayTheme.gold, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFFA09880), fontSize: 11)),
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
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AiprayTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                session.usedVoiceTracking ? Icons.mic : Icons.auto_stories,
                color: AiprayTheme.gold, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.chantTitle,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(_formatDate(session.startTime),
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(session.durationFormatted,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                if (session.roundsCompleted > 0)
                  Text('${session.roundsCompleted} รอบ',
                      style: TextStyle(color: AiprayTheme.gold.withValues(alpha: 0.7), fontSize: 11)),
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
