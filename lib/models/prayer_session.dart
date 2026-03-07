class PrayerSession {
  final String id;
  final String chantId;
  final String chantTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int roundsCompleted;
  final int totalLines;
  final int linesReached;
  final bool usedVoiceTracking;

  const PrayerSession({
    required this.id,
    required this.chantId,
    required this.chantTitle,
    required this.startTime,
    this.endTime,
    this.roundsCompleted = 0,
    this.totalLines = 0,
    this.linesReached = 0,
    this.usedVoiceTracking = false,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  String get durationFormatted {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  PrayerSession copyWith({
    DateTime? endTime,
    int? roundsCompleted,
    int? linesReached,
  }) =>
      PrayerSession(
        id: id,
        chantId: chantId,
        chantTitle: chantTitle,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        roundsCompleted: roundsCompleted ?? this.roundsCompleted,
        totalLines: totalLines,
        linesReached: linesReached ?? this.linesReached,
        usedVoiceTracking: usedVoiceTracking,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chantId': chantId,
        'chantTitle': chantTitle,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'roundsCompleted': roundsCompleted,
        'totalLines': totalLines,
        'linesReached': linesReached,
        'usedVoiceTracking': usedVoiceTracking,
      };

  factory PrayerSession.fromJson(Map<String, dynamic> json) => PrayerSession(
        id: json['id'] as String,
        chantId: json['chantId'] as String,
        chantTitle: json['chantTitle'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        roundsCompleted: json['roundsCompleted'] as int? ?? 0,
        totalLines: json['totalLines'] as int? ?? 0,
        linesReached: json['linesReached'] as int? ?? 0,
        usedVoiceTracking: json['usedVoiceTracking'] as bool? ?? false,
      );
}
