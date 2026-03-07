import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/chants/all_chants.dart';
import '../models/chant.dart';
import 'chant_detail_screen.dart';

class ChantListScreen extends StatefulWidget {
  const ChantListScreen({super.key});

  @override
  State<ChantListScreen> createState() => _ChantListScreenState();
}

class _ChantListScreenState extends State<ChantListScreen> {
  ChantCategory? _selectedCategory;
  String _search = '';

  List<Chant> get _filtered {
    var list = allChants.toList();
    if (_selectedCategory != null) {
      list = list.where((c) => c.category == _selectedCategory).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((c) {
        return c.title.toLowerCase().contains(q) ||
            (c.subtitle?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บทสวดมนต์',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AiprayTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${allChants.length} บท',
                  style: const TextStyle(color: Color(0xFFA09880)),
                ),
                const SizedBox(height: 12),

                // Search
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาบทสวด...',
                    hintStyle: const TextStyle(color: Color(0xFF666666)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                    filled: true,
                    fillColor: const Color(0xFF242424),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: 'ทั้งหมด',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...ChantCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: '${cat.icon} ${cat.label}',
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Chant list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบบทสวด',
                      style: TextStyle(color: Color(0xFFA09880)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final chant = _filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChantCard(chant: chant),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AiprayTheme.gold.withValues(alpha: 0.2)
              : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AiprayTheme.gold
                : const Color(0xFF333333),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AiprayTheme.gold : const Color(0xFFA09880),
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ChantCard extends StatelessWidget {
  final Chant chant;
  const _ChantCard({required this.chant});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF242424),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChantDetailScreen(chant: chant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AiprayTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  chant.category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    if (chant.subtitle != null)
                      Text(
                        chant.subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.format_list_numbered,
                            size: 14, color: AiprayTheme.gold.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '${chant.lineCount} บรรทัด',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                        if (chant.estimatedDuration != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined,
                              size: 14,
                              color: AiprayTheme.gold.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '~${chant.estimatedDuration!.inMinutes} นาที',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF666666)),
            ],
          ),
        ),
      ),
    );
  }
}
