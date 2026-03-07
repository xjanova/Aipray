import 'package:flutter/material.dart';
import '../main.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      icon: Icons.self_improvement,
      title: 'ยินดีต้อนรับสู่ Aipray',
      subtitle: 'สวดมนต์อัจฉริยะ',
      description: 'แอปสวดมนต์ที่ใช้ AI ติดตามตำแหน่งการสวด\n'
          'พร้อมบทสวดมนต์ครบถ้วนทุกบท',
    ),
    _PageData(
      icon: Icons.mic,
      title: 'ฟังเสียงสวด',
      subtitle: 'จับตำแหน่งอัตโนมัติ',
      description: 'เปิดไมค์แล้วสวดมนต์ตามปกติ\n'
          'แอปจะติดตามว่าคุณสวดถึงบรรทัดไหนแล้ว',
    ),
    _PageData(
      icon: Icons.repeat,
      title: 'นับรอบให้คุณ',
      subtitle: 'ไม่ต้องนับเอง',
      description: 'เมื่อสวดจบ 1 รอบ ระบบจะนับให้อัตโนมัติ\n'
          'พร้อมสั่นเตือนเบาๆ เมื่อจบรอบ',
    ),
    _PageData(
      icon: Icons.volunteer_activism,
      title: 'ร่วมพัฒนา AI',
      subtitle: 'บริจาคเสียงสวดมนต์',
      description: 'คุณสามารถเลือกบริจาคเสียงสวดมนต์\n'
          'เพื่อช่วยพัฒนา AI ฟังภาษาไทยให้ดียิ่งขึ้น',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await storageService.setSetting('seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'ข้าม',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                gold.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              radius: 0.8,
                            ),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: gold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.subtitle,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? gold
                              : gold.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(isLast ? 'เริ่มสวดมนต์' : 'ถัดไป'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
