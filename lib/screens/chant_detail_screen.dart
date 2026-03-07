import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../main.dart';
import '../models/chant.dart';
import 'prayer_session_screen.dart';

class ChantDetailScreen extends StatefulWidget {
  final Chant chant;
  const ChantDetailScreen({super.key, required this.chant});

  @override
  State<ChantDetailScreen> createState() => _ChantDetailScreenState();
}

class _ChantDetailScreenState extends State<ChantDetailScreen> {
  late bool _isFav;
  double _fontSize = 18;

  @override
  void initState() {
    super.initState();
    _isFav = storageService.isFavorite(widget.chant.id);
    _fontSize = storageService.getSetting<double>('fontSize') ?? 18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chant.title),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? Colors.redAccent : null,
            ),
            onPressed: () async {
              await storageService.toggleFavorite(widget.chant.id);
              setState(() => _isFav = !_isFav);
            },
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields),
            onSelected: (size) {
              setState(() => _fontSize = size);
              storageService.setSetting('fontSize', size);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 14.0, child: Text('เล็ก')),
              const PopupMenuItem(value: 18.0, child: Text('ปกติ')),
              const PopupMenuItem(value: 22.0, child: Text('ใหญ่')),
              const PopupMenuItem(value: 26.0, child: Text('ใหญ่มาก')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chant info
          if (widget.chant.description != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AiprayTheme.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AiprayTheme.gold.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AiprayTheme.gold.withValues(alpha: 0.6), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.chant.description!,
                      style: TextStyle(
                        color: AiprayTheme.gold.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lines
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.chant.lines.length,
              itemBuilder: (context, i) {
                final line = widget.chant.lines[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AiprayTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: AiprayTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line.text,
                            style: TextStyle(
                              color: const Color(0xFFF5F0E8),
                              fontSize: _fontSize,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrayerSessionScreen(
                          chant: widget.chant,
                          voiceMode: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('ฟังเสียงสวด'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrayerSessionScreen(
                          chant: widget.chant,
                          voiceMode: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('อ่านสวด'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
