import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../main.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  late bool _contributeEnabled;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _contributeEnabled =
        storageService.getSetting<bool>('contributeData') ?? false;
    _uploadedCount =
        storageService.getSetting<int>('uploadedAudioCount') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('มีส่วนร่วมพัฒนา AI')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AiprayTheme.gold.withValues(alpha: 0.15),
                  AiprayTheme.gold.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AiprayTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AiprayTheme.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology,
                      color: AiprayTheme.gold, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ช่วยสอน AI ฟังเสียงสวดมนต์',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'เมื่อคุณสวดมนต์กับ Aipray ข้อมูลเสียงจะถูกส่ง (แบบไม่ระบุตัวตน) '
                  'เพื่อฝึก AI ให้จับเสียงสวดมนต์ภาษาไทยได้แม่นยำขึ้น',
                  style: TextStyle(color: Color(0xFFA09880), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    color: AiprayTheme.gold, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เปิดการส่งข้อมูล',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _contributeEnabled ? 'กำลังส่งข้อมูลเมื่อเชื่อมต่อ WiFi' : 'ปิดอยู่',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _contributeEnabled,
                  onChanged: (v) {
                    setState(() => _contributeEnabled = v);
                    storageService.setSetting('contributeData', v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สถิติการมีส่วนร่วม',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.audio_file,
                  label: 'ตัวอย่างเสียงที่ส่งแล้ว',
                  value: '$_uploadedCount',
                ),
                const SizedBox(height: 8),
                _StatRow(
                  icon: Icons.group,
                  label: 'ผู้มีส่วนร่วมทั้งหมด',
                  value: 'กำลังโหลด...',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // How it works
          const Text(
            'ทำงานอย่างไร?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _StepCard(
            step: 1,
            title: 'บันทึกเสียง',
            description: 'เมื่อคุณสวดมนต์ เสียงจะถูกบันทึกเป็นชิ้นเล็กๆ',
            icon: Icons.mic,
          ),
          _StepCard(
            step: 2,
            title: 'ตรวจสอบคุณภาพ',
            description: 'ระบบจะเลือกเฉพาะเสียงที่ชัดเจนและมีคุณภาพ',
            icon: Icons.verified,
          ),
          _StepCard(
            step: 3,
            title: 'ส่งแบบไม่ระบุตัวตน',
            description: 'ข้อมูลจะถูกส่งผ่าน WiFi โดยไม่มีข้อมูลส่วนตัว',
            icon: Icons.security,
          ),
          _StepCard(
            step: 4,
            title: 'ฝึก AI Model',
            description:
                'เสียงจะถูกใช้ fine-tune โมเดล Whisper Thai เพื่อจับเสียงสวดมนต์ได้ดีขึ้น',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 24),

          // Privacy notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2640),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip, color: Color(0xFF3B82F6), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ความเป็นส่วนตัว',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ข้อมูลทั้งหมดถูกส่งแบบไม่ระบุตัวตน ไม่มีการเก็บชื่อ อีเมล หรือข้อมูลส่วนตัวใดๆ '
                        'คุณสามารถปิดการส่งข้อมูลได้ตลอดเวลา',
                        style:
                            TextStyle(color: Color(0xFFAABBDD), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AiprayTheme.gold, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
        const Spacer(),
        Text(value,
            style:
                TextStyle(color: AiprayTheme.gold, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AiprayTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$step',
                style: TextStyle(
                    color: AiprayTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(description,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),
            Icon(icon, color: AiprayTheme.gold.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}
