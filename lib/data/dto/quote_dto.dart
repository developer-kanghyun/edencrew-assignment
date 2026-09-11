import '../../models/quote.dart';

/// 실시간 시세 응답의 `datas` 한 건. 네이버가 준 축약 필드명을 그대로 쓴다.
class QuoteDto {
  const QuoteDto({
    required this.cd,
    required this.nv,
    required this.pcv,
    required this.ov,
    required this.hv,
    required this.lv,
    required this.aq,
    required this.countOfListedStock,
  });

  factory QuoteDto.fromJson(Map<String, dynamic> json) {
    return QuoteDto(
      cd: json['cd'] as String? ?? '',
      nv: _asInt(json['nv']),
      pcv: _asInt(json['pcv']),
      ov: _asInt(json['ov']),
      hv: _asInt(json['hv']),
      lv: _asInt(json['lv']),
      aq: _asInt(json['aq']),
      countOfListedStock: _asInt(json['countOfListedStock']),
    );
  }

  /// 종목코드
  final String cd;

  /// 현재가
  final int nv;

  /// 전일 종가
  final int pcv;

  /// 시가
  final int ov;

  /// 고가
  final int hv;

  /// 저가
  final int lv;

  /// 누적 거래량
  final int aq;

  /// 상장 주식 수. 시가총액 계산에 쓴다.
  final int countOfListedStock;

  /// 숫자 필드가 정수로 올지 실수로 올지 응답마다 다를 수 있어 num으로 받아 맞춘다.
  static int _asInt(dynamic value) => switch (value) {
    num() => value.toInt(),
    String() => int.tryParse(value.replaceAll(',', '')) ?? 0,
    _ => 0,
  };

  Quote toModel() => Quote(
    symbol: cd,
    currentPrice: nv,
    previousClose: pcv,
    open: ov,
    high: hv,
    low: lv,
    accumulatedVolume: aq,
    listedShares: countOfListedStock,
  );
}
