import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/chants/all_chants.dart';
import '../main.dart';
import '../models/chant.dart';
import '../services/update_service.dart';
import 'prayer_session_screen.dart';
import 'chant_detail_screen.dart';
import 'update_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _streakController;
  bool _showStreakCelebration = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _checkStreak();
    _checkForUpdates();
  }

  void _checkStreak() {
    final streak = storageService.streak;
    if (streak > 0 && streak % 7 == 0) {
      _showStreakCelebration = true;
      _streakController.forward();
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      final result = await updateService.checkForUpdate();
      if (result == UpdateCheckResult.updateAvailable && mounted) {
        UpdateDialog.show(context, updateService);
      }
    } catch (_) {
      // Silently ignore update check failures
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = storageService.getFavorites();
    final favorites = allChants.where((c) => favIds.contains(c.id)).toList();
    final recommended = _getSmartRecommendations();
    final streak = storageService.streak;
    final greeting = _getTimeGreeting();
    final dailyChants = allChants.where((c) => c.category == ChantCategory.daily).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Smart Header with greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Animated logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AiprayTheme.gold,
                                  AiprayTheme.gold.withValues(alpha: 0.6 + _pulseController.value * 0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AiprayTheme.gold.withValues(alpha: 0.2 + _pulseController.value * 0.15),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.self_improvement,
                                color: Color(0xFF0D0D0D), size: 30),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting.title,
                              style: TextStyle(
                                color: AiprayTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              greeting.subtitle,
                              style: const TextStyle(
                                color: AiprayTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Update button
                      ValueListenableBuilder<UpdateState>(
                        valueListenable: updateService.state,
                        builder: (context, state, _) {
                          if (state == UpdateState.updateAvailable) {
                            return GestureDetector(
                              onTap: () => UpdateDialog.show(context, updateService),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.system_update,
                                  color: Color(0xFF10B981),
                                  size: 22,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Streak + Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SmartStatsCard(
                streak: streak,
                sessions: storageService.totalSessions,
                time: storageService.totalPrayerTimeFormatted,
                rounds: storageService.totalRounds,
                showCelebration: _showStreakCelebration,
                animation: _streakController,
              ),
            ),
          ),

          // Daily inspiration
          SliverToBoxAdapter(child: _DailyInspiration()),

          // Smart recommendations
          if (recommended.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AiprayTheme.gold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'แนะนำสำหรับคุณ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AiprayTheme.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          color: AiprayTheme.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recommended.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: EdgeInsets.only(right: i < recommended.length - 1 ? 12 : 0),
                    child: _RecommendedCard(
                      chant: recommended[i].chant,
                      reason: recommended[i].reason,
                      icon: recommended[i].icon,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Quick start section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'เริ่มสวดมนต์',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _QuickStartCard(
                    icon: Icons.mic,
                    title: 'ฟังเสียงสวด',
                    subtitle: 'AI จับตำแหน่งอัตโนมัติ',
                    color: const Color(0xFF10B981),
                    onTap: () => _showChantPicker(context, voiceMode: true),
                  ),
                  const SizedBox(width: 12),
                  _QuickStartCard(
                    icon: Icons.auto_stories,
                    title: 'อ่านสวดมนต์',
                    subtitle: 'เลื่อนตามด้วยตนเอง',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _showChantPicker(context, voiceMode: false),
                  ),
                  const SizedBox(width: 12),
                  _QuickStartCard(
                    icon: Icons.play_circle_fill,
                    title: 'จำลองเสียง',
                    subtitle: 'ทดสอบระบบ AI',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrayerSessionScreen(
                            chant: allChants.first,
                            simulationMode: true,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Favorites section
          if (favorites.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'บทโปรด',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ChantTile(chant: favorites[i]),
                childCount: favorites.length,
              ),
            ),
          ],

          // Daily chants
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                children: [
                  const Text('🙏', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'ทำวัตรประจำวัน',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ChantTile(chant: dailyChants[i]),
              childCount: dailyChants.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  List<_Recommendation> _getSmartRecommendations() {
    final hour = DateTime.now().hour;
    final sessions = storageService.getSessions();
    final recommendations = <_Recommendation>[];

    // Time-based recommendations
    if (hour >= 4 && hour < 9) {
      // Morning
      final morning = allChants.where((c) => c.id == 'morning_chant').firstOrNull;
      if (morning != null) {
        recommendations.add(_Recommendation(
          chant: morning,
          reason: 'เหมาะกับช่วงเช้า',
          icon: Icons.wb_sunny,
        ));
      }
      final namo = allChants.where((c) => c.id == 'namo3').firstOrNull;
      if (namo != null) {
        recommendations.add(_Recommendation(
          chant: namo,
          reason: 'เริ่มต้นวันใหม่',
          icon: Icons.light_mode,
        ));
      }
    } else if (hour >= 17 && hour < 21) {
      // Evening
      final evening = allChants.where((c) => c.id == 'evening_chant').firstOrNull;
      if (evening != null) {
        recommendations.add(_Recommendation(
          chant: evening,
          reason: 'เหมาะกับช่วงเย็น',
          icon: Icons.nightlight_round,
        ));
      }
      final metta = allChants.where((c) => c.id == 'metta_short').firstOrNull;
      if (metta != null) {
        recommendations.add(_Recommendation(
          chant: metta,
          reason: 'แผ่เมตตาก่อนนอน',
          icon: Icons.favorite,
        ));
      }
    } else if (hour >= 21 || hour < 4) {
      // Night
      final metta = allChants.where((c) => c.id == 'phaemetta').firstOrNull;
      if (metta != null) {
        recommendations.add(_Recommendation(
          chant: metta,
          reason: 'สงบจิตใจก่อนนอน',
          icon: Icons.bedtime,
        ));
      }
    }

    // Frequency-based: recommend least used chants
    if (sessions.isNotEmpty) {
      final usedIds = sessions.map((s) => s.chantId).toSet();
      final unused = allChants.where((c) => !usedIds.contains(c.id)).take(2);
      for (final chant in unused) {
        recommendations.add(_Recommendation(
          chant: chant,
          reason: 'ยังไม่เคยลอง',
          icon: Icons.explore,
        ));
      }
    }

    // Protection chants on Wan Phra (Buddhist holy days ~ every 7-8 days)
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    if (dayOfYear % 8 == 0) {
      final protection = allChants.where((c) => c.id == 'chinabanchorn').firstOrNull;
      if (protection != null) {
        recommendations.add(_Recommendation(
          chant: protection,
          reason: 'วันมงคล',
          icon: Icons.shield,
        ));
      }
    }

    return recommendations.take(4).toList();
  }

  _TimeGreeting _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return _TimeGreeting('สวัสดีตอนเช้า 🌅', 'เริ่มต้นวันใหม่ด้วยการสวดมนต์');
    } else if (hour >= 12 && hour < 17) {
      return _TimeGreeting('สวัสดีตอนบ่าย ☀️', 'สวดมนต์เพื่อความสงบในยามบ่าย');
    } else if (hour >= 17 && hour < 21) {
      return _TimeGreeting('สวัสดีตอนเย็น 🌆', 'ปิดวันด้วยจิตอันสงบ');
    } else {
      return _TimeGreeting('ราตรีสวัสดิ์ 🌙', 'สวดมนต์ก่อนนอนเพื่อจิตที่สงบ');
    }
  }

  void _showChantPicker(BuildContext context, {required bool voiceMode}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChantPickerSheet(voiceMode: voiceMode),
    );
  }
}

class _TimeGreeting {
  final String title;
  final String subtitle;
  _TimeGreeting(this.title, this.subtitle);
}

class _Recommendation {
  final Chant chant;
  final String reason;
  final IconData icon;
  _Recommendation({required this.chant, required this.reason, required this.icon});
}

// === Smart Stats Card with streak ===
class _SmartStatsCard extends StatelessWidget {
  final int streak;
  final int sessions;
  final String time;
  final int rounds;
  final bool showCelebration;
  final Animation<double> animation;

  const _SmartStatsCard({
    required this.streak,
    required this.sessions,
    required this.time,
    required this.rounds,
    required this.showCelebration,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AiprayTheme.gold.withValues(alpha: 0.15),
            AiprayTheme.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AiprayTheme.gold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Streak banner
          if (streak > 0) ...[
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: streak >= 7
                          ? [
                              const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              const Color(0xFFEF4444).withValues(alpha: 0.2),
                            ]
                          : [
                              AiprayTheme.gold.withValues(alpha: 0.1),
                              AiprayTheme.gold.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        streak >= 30
                            ? '🔥🔥🔥'
                            : streak >= 7
                                ? '🔥🔥'
                                : '🔥',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'สวดติดต่อกัน $streak วัน!',
                        style: TextStyle(
                          color: streak >= 7
                              ? const Color(0xFFF59E0B)
                              : AiprayTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (showCelebration) ...[
                        const SizedBox(width: 8),
                        const Text('🎉', style: TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '$sessions',
                label: 'ครั้ง',
                icon: Icons.self_improvement,
              ),
              Container(
                width: 1,
                height: 40,
                color: AiprayTheme.gold.withValues(alpha: 0.2),
              ),
              _StatItem(
                value: time.isEmpty ? '0m' : time,
                label: 'เวลารวม',
                icon: Icons.timer,
              ),
              Container(
                width: 1,
                height: 40,
                color: AiprayTheme.gold.withValues(alpha: 0.2),
              ),
              _StatItem(
                value: '$rounds',
                label: 'รอบ',
                icon: Icons.loop,
              ),
              Container(
                width: 1,
                height: 40,
                color: AiprayTheme.gold.withValues(alpha: 0.2),
              ),
              _StatItem(
                value: '$streak',
                label: 'วันต่อเนื่อง',
                icon: Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AiprayTheme.gold.withValues(alpha: 0.5), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AiprayTheme.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AiprayTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

// === Recommended Card ===
class _RecommendedCard extends StatelessWidget {
  final Chant chant;
  final String reason;
  final IconData icon;

  const _RecommendedCard({
    required this.chant,
    required this.reason,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChantDetailScreen(chant: chant),
          ),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AiprayTheme.gold.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AiprayTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AiprayTheme.gold, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AiprayTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      color: AiprayTheme.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              chant.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  chant.category.icon,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  '${chant.estimatedDuration?.inMinutes ?? 0} นาที',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AiprayTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChantTile extends StatelessWidget {
  final Chant chant;
  const _ChantTile({required this.chant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: AiprayTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChantDetailScreen(chant: chant),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AiprayTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    chant.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chant.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (chant.subtitle != null)
                        Text(
                          chant.subtitle!,
                          style: const TextStyle(
                            color: AiprayTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${chant.lineCount} บรรทัด',
                  style: const TextStyle(
                    color: AiprayTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AiprayTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyInspiration extends StatelessWidget {
  static const _quotes = [
    {'th': 'มนะ สัง วะ รัง เอสะ มังคะลา นุตตะรัง', 'en': 'การฝึกจิตเป็นมงคลอันสูงสุด'},
    {'th': 'สัพพะทานัง ธัมมะทานัง ชินาติ', 'en': 'การให้ธรรมเป็นทาน ชนะการให้ทั้งปวง'},
    {'th': 'ขันตี ปะระมัง ตะโป ตีติกขา', 'en': 'ขันติ ความอดทน เป็นตบะอย่างยิ่ง'},
    {'th': 'อัปปะมาเทนะ สัมปาเทถะ', 'en': 'ท่านทั้งหลายจงยังความไม่ประมาทให้ถึงพร้อม'},
    {'th': 'นัตถิ สันติ ปะรัง สุขัง', 'en': 'สุขอื่นยิ่งกว่าความสงบไม่มี'},
    {'th': 'สัพเพ สัตตา สุขิตา โหนตุ', 'en': 'ขอสัตว์ทั้งหลายจงมีความสุข'},
    {'th': 'จิตตัง ทันตัง สุขาวะหัง', 'en': 'จิตที่ฝึกดีแล้วนำความสุขมาให้'},
  ];

  @override
  Widget build(BuildContext context) {
    final dayIndex = DateTime.now().day % _quotes.length;
    final quote = _quotes[dayIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote,
                    color: AiprayTheme.gold.withValues(alpha: 0.6), size: 20),
                const SizedBox(width: 6),
                Text(
                  'พุทธวจนะประจำวัน',
                  style: TextStyle(
                    color: AiprayTheme.gold.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quote['th']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              quote['en']!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChantPickerSheet extends StatelessWidget {
  final bool voiceMode;
  const _ChantPickerSheet({required this.voiceMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              voiceMode ? 'เลือกบทสวด (ฟังเสียง AI)' : 'เลือกบทสวด (อ่าน)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allChants.length,
              itemBuilder: (ctx, i) {
                final chant = allChants[i];
                return ListTile(
                  leading: Text(chant.category.icon,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(chant.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: chant.subtitle != null
                      ? Text(chant.subtitle!,
                          style: const TextStyle(color: AiprayTheme.textSecondary))
                      : null,
                  trailing: const Icon(Icons.play_arrow,
                      color: Color(0xFFD4A647)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrayerSessionScreen(
                          chant: chant,
                          voiceMode: voiceMode,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
