import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../main.dart';
import '../services/update_service.dart';
import 'contribute_screen.dart';
import 'update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoScroll;
  late bool _hapticFeedback;
  late bool _contributeData;
  late double _fontSize;
  late double _scrollSpeed;

  @override
  void initState() {
    super.initState();
    _autoScroll = storageService.getSetting<bool>('autoScroll') ?? true;
    _hapticFeedback = storageService.getSetting<bool>('hapticFeedback') ?? true;
    _contributeData =
        storageService.getSetting<bool>('contributeData') ?? false;
    _fontSize = storageService.getSetting<double>('fontSize') ?? 18.0;
    _scrollSpeed = storageService.getSetting<double>('scrollSpeed') ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'ตั้งค่า',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AiprayTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Display section
          _SectionHeader(title: 'การแสดงผล'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SliderTile(
                icon: Icons.text_fields,
                title: 'ขนาดตัวอักษร',
                value: _fontSize,
                min: 14,
                max: 30,
                label: '${_fontSize.toInt()}',
                onChanged: (v) {
                  setState(() => _fontSize = v);
                  storageService.setSetting('fontSize', v);
                },
              ),
              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.swap_vert,
                title: 'เลื่อนอัตโนมัติ',
                subtitle: 'เลื่อนตามบรรทัดปัจจุบัน',
                value: _autoScroll,
                onChanged: (v) {
                  setState(() => _autoScroll = v);
                  storageService.setSetting('autoScroll', v);
                },
              ),
              const Divider(height: 1),
              _SliderTile(
                icon: Icons.speed,
                title: 'ความเร็วเลื่อน',
                value: _scrollSpeed,
                min: 0.5,
                max: 2.0,
                label: '${_scrollSpeed.toStringAsFixed(1)}x',
                onChanged: (v) {
                  setState(() => _scrollSpeed = v);
                  storageService.setSetting('scrollSpeed', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Audio section
          _SectionHeader(title: 'เสียงและการสั่น'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.vibration,
                title: 'สั่นเมื่อครบรอบ',
                subtitle: 'สั่นเตือนเมื่อสวดครบรอบ',
                value: _hapticFeedback,
                onChanged: (v) {
                  setState(() => _hapticFeedback = v);
                  storageService.setSetting('hapticFeedback', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI section
          _SectionHeader(title: 'AI และข้อมูล'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.cloud_upload_outlined,
                title: 'มีส่วนร่วมพัฒนา AI',
                subtitle: 'ส่งข้อมูลเสียงสวดเพื่อฝึก AI (ไม่ระบุตัวตน)',
                value: _contributeData,
                onChanged: (v) {
                  setState(() => _contributeData = v);
                  storageService.setSetting('contributeData', v);
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ContributeScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AiprayTheme.gold, size: 22),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'ดูรายละเอียดเพิ่มเติม',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Update section
          _SectionHeader(title: 'อัปเดต'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.system_update, color: AiprayTheme.gold, size: 22),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ตรวจสอบอัปเดต',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          Text(
                            'ดาวน์โหลดเวอร์ชันใหม่จาก GitHub',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<UpdateState>(
                      valueListenable: updateService.state,
                      builder: (context, state, _) {
                        if (state == UpdateState.checking) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AiprayTheme.gold),
                          );
                        }
                        if (state == UpdateState.updateAvailable) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('มีอัปเดต!', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                          );
                        }
                        return GestureDetector(
                          onTap: () async {
                            final result = await updateService.checkForUpdate(force: true);
                            if (!context.mounted) return;
                            if (result == UpdateCheckResult.updateAvailable) {
                              UpdateDialog.show(context, updateService);
                            } else if (result == UpdateCheckResult.noUpdate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('คุณใช้เวอร์ชันล่าสุดแล้ว ✓'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ไม่สามารถตรวจสอบอัปเดตได้'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AiprayTheme.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AiprayTheme.gold.withValues(alpha: 0.3)),
                            ),
                            child: const Text('ตรวจสอบ', style: TextStyle(color: AiprayTheme.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: 'เกี่ยวกับ'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.info_outline,
                title: 'เวอร์ชัน',
                value: UpdateService.currentVersion,
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.code,
                title: 'พัฒนาโดย',
                value: 'xjanova',
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.self_improvement,
                title: 'Aipray',
                value: 'สวดมนต์อัจฉริยะ',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFA09880),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AiprayTheme.gold, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AiprayTheme.gold, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AiprayTheme.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AiprayTheme.gold,
              inactiveTrackColor: AiprayTheme.gold.withValues(alpha: 0.2),
              thumbColor: AiprayTheme.gold,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AiprayTheme.gold, size: 22),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
