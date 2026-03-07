import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/chants/all_chants.dart';
import '../main.dart';
import '../models/chant.dart';
import 'prayer_session_screen.dart';
import 'chant_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favIds = storageService.getFavorites();
    final favorites = allChants.where((c) => favIds.contains(c.id)).toList();
    final dailyChants =
        allChants.where((c) => c.category == ChantCategory.daily).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AiprayTheme.gold,
                              AiprayTheme.gold.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.self_improvement,
                            color: Color(0xFF0D0D0D), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aipray',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AiprayTheme.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                          ),
                          Text(
                            'สวดมนต์อัจฉริยะ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats card
                  _StatsCard(),
                  const SizedBox(height: 24),

                  // Quick start
                  Text(
                    'เริ่มสวดมนต์',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Daily inspiration
          SliverToBoxAdapter(
            child: _DailyInspiration(),
          ),

          // Quick start buttons
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
                    subtitle: 'จับตำแหน่งอัตโนมัติ',
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
                    subtitle: 'ทดสอบระบบ',
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'บทโปรด',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'ทำวัตรประจำวัน',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sessions = storageService.totalSessions;
    final time = storageService.totalPrayerTimeFormatted;
    final rounds = storageService.totalRounds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AiprayTheme.gold.withValues(alpha: 0.15),
            AiprayTheme.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AiprayTheme.gold.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$sessions', label: 'ครั้ง'),
          Container(width: 1, height: 40, color: AiprayTheme.gold.withValues(alpha: 0.2)),
          _StatItem(value: time.isEmpty ? '0m' : time, label: 'เวลารวม'),
          Container(width: 1, height: 40, color: AiprayTheme.gold.withValues(alpha: 0.2)),
          _StatItem(value: '$rounds', label: 'รอบ'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD4A647),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA09880), fontSize: 12),
        ),
      ],
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
        width: 150,
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
              style: const TextStyle(color: Color(0xFFA09880), fontSize: 11),
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
                            color: Color(0xFFA09880),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${chant.lineCount} บรรทัด',
                  style: const TextStyle(
                    color: Color(0xFFA09880),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFA09880)),
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
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
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
              voiceMode ? 'เลือกบทสวด (ฟังเสียง)' : 'เลือกบทสวด (อ่าน)',
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
                          style: const TextStyle(color: Color(0xFFA09880)))
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
