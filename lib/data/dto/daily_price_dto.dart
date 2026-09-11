import '../../models/daily_price.dart';

/// 일별 시세 표의 한 행. HTML에서 뽑아낸 문자열을 그대로 담는다.
///
/// 표의 숫자에는 천 단위 쉼표가 붙어 있고 날짜는 `2026.09.11` 형태라, 모델로
/// 옮기면서 숫자와 `yyyyMMdd`로 바꾼다.
class DailyPriceDto {
  const DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });

  final String localDate;
  final String closePrice;
  final String openPrice;
  final String highPrice;
  final String lowPrice;
  final String accumulatedTradingVolume;

  static final RegExp _datePattern = RegExp(r'^\d{4}\.\d{2}\.\d{2}$');

  /// 표에는 빈 줄과 헤더도 섞여 있어, 날짜 칸 모양으로 실제 데이터 행을 가린다.
  bool get isDataRow => _datePattern.hasMatch(localDate);

  DailyPrice toModel() => DailyPrice(
    date: localDate.replaceAll('.', ''),
    closePrice: _asInt(closePrice),
    openPrice: _asInt(openPrice),
    highPrice: _asInt(highPrice),
    lowPrice: _asInt(lowPrice),
    accumulatedTradingVolume: _asInt(accumulatedTradingVolume),
  );

  static int _asInt(String raw) =>
      int.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
}
