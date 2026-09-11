/// 일별 시세 한 줄. 상세 화면의 차트와 `일별 시세` 표가 쓴다.
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  /// `yyyyMMdd` 형태로 정규화한 거래일. 응답은 `2026.09.11`로 온다.
  final String date;

  final int closePrice;
  final int openPrice;
  final int lowPrice;
  final int highPrice;
  final int accumulatedTradingVolume;

  /// 표에 `MM.DD`로 표시할 때 쓴다.
  String get monthDay =>
      '${date.substring(4, 6)}.${date.substring(6, 8)}';
}
