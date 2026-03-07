class ChantLine {
  final int index;
  final String text;
  final String? transliteration;
  final String? meaning;

  const ChantLine({
    required this.index,
    required this.text,
    this.transliteration,
    this.meaning,
  });

  factory ChantLine.fromJson(Map<String, dynamic> json, int index) {
    if (json case {'text': final String text}) {
      return ChantLine(
        index: index,
        text: text,
        transliteration: json['transliteration'] as String?,
        meaning: json['meaning'] as String?,
      );
    }
    return ChantLine(index: index, text: json.toString());
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        if (transliteration != null) 'transliteration': transliteration,
        if (meaning != null) 'meaning': meaning,
      };
}

enum ChantCategory {
  daily('ทำวัตรประจำวัน', '🙏'),
  protection('บทป้องกันภัย', '🛡️'),
  meditation('บทภาวนา', '🧘'),
  merit('บทกรวดน้ำ-แผ่เมตตา', '💛'),
  sutta('พระสูตร', '📿'),
  special('บทพิเศษ', '✨');

  final String label;
  final String icon;
  const ChantCategory(this.label, this.icon);
}

class Chant {
  final String id;
  final String title;
  final String? subtitle;
  final ChantCategory category;
  final List<ChantLine> lines;
  final String? description;
  final Duration? estimatedDuration;
  final bool isFavorite;

  const Chant({
    required this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.lines,
    this.description,
    this.estimatedDuration,
    this.isFavorite = false,
  });

  Chant copyWith({bool? isFavorite}) => Chant(
        id: id,
        title: title,
        subtitle: subtitle,
        category: category,
        lines: lines,
        description: description,
        estimatedDuration: estimatedDuration,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  int get lineCount => lines.length;

  factory Chant.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List;
    final lines = rawLines.asMap().entries.map((e) {
      if (e.value is String) {
        return ChantLine(index: e.key, text: e.value as String);
      }
      return ChantLine.fromJson(e.value as Map<String, dynamic>, e.key);
    }).toList();

    return Chant(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      category: ChantCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String? ?? 'daily'),
        orElse: () => ChantCategory.daily,
      ),
      lines: lines,
      description: json['description'] as String?,
      estimatedDuration: json['durationMinutes'] != null
          ? Duration(minutes: json['durationMinutes'] as int)
          : null,
    );
  }
}
