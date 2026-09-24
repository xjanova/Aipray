/// What a line of release notes is, which decides how the dialog draws it.
enum NoteKind { heading, bullet, numbered, plain }

/// A run of text inside a line, bold or not.
class NoteSpan {
  final String text;
  final bool bold;

  const NoteSpan(this.text, {this.bold = false});
}

/// One line of release notes, with the Markdown taken out.
class NoteLine {
  final NoteKind kind;
  final List<NoteSpan> spans;

  /// The item number as written (`1.`), empty unless [kind] is numbered.
  final String number;

  /// A blank line or a new heading comes before this line.
  final bool gapBefore;

  const NoteLine(
    this.kind,
    this.spans, {
    this.number = '',
    this.gapBefore = false,
  });

  String get text => spans.map((s) => s.text).join();
}

/// Turns release notes written in Markdown (the GitHub release body) into
/// lines the update dialog can show as text.
///
/// Headings, bullets, numbered items and `**bold**` keep their meaning; other
/// marks are taken out. Links keep only their text and URLs are dropped, so a
/// customer never sees a link to GitHub or anywhere else. Lines left with
/// nothing to read are dropped too.
List<NoteLine> parseReleaseNotes(String markdown) {
  final lines = <NoteLine>[];
  var gap = false;

  for (final raw in markdown.replaceAll(_comment, '').split(_lineBreak)) {
    var line = raw.replaceFirst(_quote, '').trim();
    if (_blank.hasMatch(line)) {
      gap = true;
      continue;
    }

    var kind = NoteKind.plain;
    var number = '';
    if (_heading.firstMatch(line) case final m?) {
      kind = NoteKind.heading;
      line = m[1]!;
    } else if (_bullet.firstMatch(line) case final m?) {
      kind = NoteKind.bullet;
      line = m[1]!;
    } else if (_numbered.firstMatch(line) case final m?) {
      kind = NoteKind.numbered;
      number = m[1]!;
      line = m[2]!;
    }

    final linked =
        line.replaceAll(_image, '').replaceAllMapped(_link, (m) => m[1]!);
    final unlinked = linked.replaceAll(_url, ' ');
    final spans = <NoteSpan>[];
    _addSpans(spans, _tidy(unlinked.replaceAll(_tag, ' ')), false);
    final text = spans.map((s) => s.text).join();

    // Nothing left to read, or only the label of a URL that was dropped:
    // "**Full Changelog**: https://github.com/..."
    if (!_readable.hasMatch(text) ||
        (unlinked != linked && text.endsWith(':'))) {
      continue;
    }

    lines.add(NoteLine(
      kind,
      spans,
      number: number,
      gapBefore: lines.isNotEmpty && (gap || kind == NoteKind.heading),
    ));
    gap = false;
  }
  return lines;
}

void _addSpans(List<NoteSpan> spans, String text, bool bold) {
  var start = 0;
  for (final m in _emphasis.allMatches(text)) {
    _addSpan(spans, text.substring(start, m.start), bold);
    final strong = m[2] ?? m[3];
    if (m[1] != null) {
      _addSpan(spans, m[1]!, bold); // `code` is shown as written
    } else if (strong != null) {
      _addSpans(spans, strong, true);
    } else {
      _addSpans(spans, m[4]!, bold); // *italic* loses only its marks
    }
    start = m.end;
  }
  _addSpan(spans, text.substring(start), bold);
}

void _addSpan(List<NoteSpan> spans, String text, bool bold) {
  if (text.isEmpty) return;
  if (spans.isNotEmpty && spans.last.bold == bold) {
    spans.last = NoteSpan(spans.last.text + text, bold: bold);
  } else {
    spans.add(NoteSpan(text, bold: bold));
  }
}

String _tidy(String text) =>
    text.replaceAll(_emptyBrackets, '').replaceAll(_spaces, ' ').trim();

final _lineBreak = RegExp(r'\r\n?|\n');
final _comment = RegExp(r'<!--[\s\S]*?-->');
final _quote = RegExp(r'^\s*(?:>\s?)+');

// Blank lines, rules (---, ***, ___, and === under a heading), code fences
final _blank =
    RegExp(r'^(?:(?:-\s*){3,}|(?:\*\s*){3,}|(?:_\s*){3,}|=+|```.*|~~~.*)?$');

final _heading = RegExp(r'^#{1,6}\s+(.*?)(?:\s+#+)?$');
final _bullet = RegExp(r'^[-*+]\s+(?:\[[ xX]\]\s+)?(.*)$');
final _numbered = RegExp(r'^(\d{1,9}[.)])\s+(.*)$');

final _image = RegExp(r'!\[[^\]]*\]\([^)]*\)');
final _link = RegExp(r'\[([^\]]*)\]\([^)]*\)');

// <autolinks>, scheme://..., www...., host.tld/path, and GitHub hosts even
// without a path. A URL ends at anything but printable ASCII, and at quotes,
// brackets, * and `, so Thai text and Markdown marks after it are kept.
final _url = RegExp(
  r'<[a-z][a-z0-9+.-]*:[^\s>]*>'
  r'|\b[a-z][a-z0-9+.-]*://[!#-&+-;=?-_a-~]*'
  r'|\bwww\.[!#-&+-;=?-_a-~]*'
  r'|\b(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?/[!#-&+-;=?-_a-~]*'
  r'|\b(?:[a-z0-9-]+\.)*(?:github\.(?:com|io)|githubusercontent\.com|git\.io)\b',
  caseSensitive: false,
);

final _tag = RegExp(r'</?[a-z][a-z0-9-]*(?:\s[^>]*)?/?>', caseSensitive: false);
final _emptyBrackets = RegExp(r'\(\s*\)|\[\s*\]');
final _spaces = RegExp(r'\s+');

// `code`, **bold**, __bold__, *italic*
final _emphasis = RegExp(
  r'`([^`]+)`'
  r'|\*\*(?=\S)(.+?)(?<=\S)\*\*'
  r'|__(?=\S)(.+?)(?<=\S)__'
  r'|\*(?=\S)(.+?)(?<=\S)\*',
);

// Anything but spaces and punctuation
final _readable = RegExp(r'[^\s\p{P}]', unicode: true);
