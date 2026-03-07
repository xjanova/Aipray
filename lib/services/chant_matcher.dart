import '../models/chant.dart';

class MatchResult {
  final String chantId;
  final int lineIndex;
  final String matchedText;
  final double confidence;

  const MatchResult({
    required this.chantId,
    required this.lineIndex,
    required this.matchedText,
    required this.confidence,
  });
}

class ChantMatcher {
  List<_IndexedLine> _index = [];
  String? _activeChantId;
  int _lastMatchedLine = -1;

  void buildIndex(List<Chant> chants) {
    _index = chants.expand((chant) {
      return chant.lines.map((line) => _IndexedLine(
            chantId: chant.id,
            lineIndex: line.index,
            text: line.text,
            normalized: _normalize(line.text),
          ));
    }).toList();
  }

  void setActiveChant(String chantId) {
    _activeChantId = chantId;
    _lastMatchedLine = -1;
  }

  void reset() {
    _activeChantId = null;
    _lastMatchedLine = -1;
  }

  MatchResult? findMatch(String transcript) {
    final norm = _normalize(transcript);
    if (norm.length < 3) return null;

    // Filter to active chant if set
    final candidates = _activeChantId != null
        ? _index.where((l) => l.chantId == _activeChantId).toList()
        : _index;

    if (candidates.isEmpty) return null;

    // Try exact substring match first
    for (final item in candidates) {
      if (norm.contains(item.normalized) || item.normalized.contains(norm)) {
        _lastMatchedLine = item.lineIndex;
        return MatchResult(
          chantId: item.chantId,
          lineIndex: item.lineIndex,
          matchedText: item.text,
          confidence: 1.0,
        );
      }
    }

    // Sequential prediction: prioritize next expected line
    if (_lastMatchedLine >= 0) {
      final nextLine = _lastMatchedLine + 1;
      final nextCandidates =
          candidates.where((l) => l.lineIndex == nextLine).toList();
      for (final item in nextCandidates) {
        final score = _similarityScore(norm, item.normalized);
        if (score >= 0.4) {
          _lastMatchedLine = item.lineIndex;
          return MatchResult(
            chantId: item.chantId,
            lineIndex: item.lineIndex,
            matchedText: item.text,
            confidence: score,
          );
        }
      }
    }

    // Fuzzy match with character overlap
    _IndexedLine? best;
    double bestScore = 0;

    for (final item in candidates) {
      final score = _similarityScore(norm, item.normalized);
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (best != null && bestScore >= 0.5) {
      _lastMatchedLine = best.lineIndex;
      return MatchResult(
        chantId: best.chantId,
        lineIndex: best.lineIndex,
        matchedText: best.text,
        confidence: bestScore,
      );
    }

    return null;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[\u0E30-\u0E3A\u0E47-\u0E4E]'), '') // Remove Thai marks
        .replaceAll(RegExp(r'[()（）\[\],.;:!?]'), '');
  }

  static double _similarityScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    // Bigram similarity (Dice coefficient)
    final bigramsA = _bigrams(a);
    final bigramsB = _bigrams(b);

    if (bigramsA.isEmpty || bigramsB.isEmpty) {
      // Fallback to character overlap
      int overlap = 0;
      for (final ch in a.runes) {
        if (b.contains(String.fromCharCode(ch))) overlap++;
      }
      return overlap / a.length;
    }

    int intersection = 0;
    final bCopy = List<String>.from(bigramsB);
    for (final bg in bigramsA) {
      final idx = bCopy.indexOf(bg);
      if (idx >= 0) {
        intersection++;
        bCopy.removeAt(idx);
      }
    }

    return (2 * intersection) / (bigramsA.length + bigramsB.length);
  }

  static List<String> _bigrams(String s) {
    if (s.length < 2) return [];
    return List.generate(s.length - 1, (i) => s.substring(i, i + 2));
  }
}

class _IndexedLine {
  final String chantId;
  final int lineIndex;
  final String text;
  final String normalized;

  const _IndexedLine({
    required this.chantId,
    required this.lineIndex,
    required this.text,
    required this.normalized,
  });
}
