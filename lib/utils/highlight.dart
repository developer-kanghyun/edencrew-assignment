/// 종목명을 검색어와 겹치는 조각과 아닌 조각으로 나눈 결과.
class HighlightSegment {
  const HighlightSegment(this.text, {required this.matched});

  final String text;
  final bool matched;

  @override
  bool operator ==(Object other) =>
      other is HighlightSegment &&
      other.text == text &&
      other.matched == matched;

  @override
  int get hashCode => Object.hash(text, matched);

  @override
  String toString() => '${matched ? '[' : ''}$text${matched ? ']' : ''}';
}

/// 검색어와 일치하는 부분을 표시하기 위해 종목명을 조각으로 나눈다.
///
/// 위젯이 아니라 순수 함수로 둬서 화면 없이 검증할 수 있게 했다.
/// 영문 종목명을 소문자로 검색하는 경우가 있어 대소문자는 구분하지 않는다.
List<HighlightSegment> splitHighlight(String text, String query) {
  final String needle = query.trim();
  if (needle.isEmpty || text.isEmpty) {
    return <HighlightSegment>[HighlightSegment(text, matched: false)];
  }

  final String haystackLower = text.toLowerCase();
  final String needleLower = needle.toLowerCase();

  final List<HighlightSegment> segments = <HighlightSegment>[];
  int cursor = 0;

  while (cursor < text.length) {
    final int hit = haystackLower.indexOf(needleLower, cursor);
    if (hit < 0) break;

    if (hit > cursor) {
      segments.add(HighlightSegment(text.substring(cursor, hit), matched: false));
    }
    segments.add(
      HighlightSegment(
        text.substring(hit, hit + needle.length),
        matched: true,
      ),
    );
    cursor = hit + needle.length;
  }

  if (cursor < text.length) {
    segments.add(HighlightSegment(text.substring(cursor), matched: false));
  }
  return segments;
}
