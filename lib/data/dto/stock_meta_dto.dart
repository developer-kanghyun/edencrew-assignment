import '../../models/search_result.dart';

/// 종목 메타데이터 응답. 종목을 가리키는 기본 정보만 쓴다.
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetaDto.fromJson(Map<String, dynamic> json) {
    return StockMetaDto(
      symbolCode: json['symbolCode'] as String? ?? '',
      stockName: json['stockName'] as String? ?? '',
      stockExchangeNameKor: json['stockExchangeNameKor'] as String? ?? '',
    );
  }

  final String symbolCode;
  final String stockName;

  /// `코스피` 또는 `코스닥`. 화면의 `005930 · 코스피`에서 뒷부분이 이 값이다.
  final String stockExchangeNameKor;

  /// 종목을 가리키는 세 값(코드·이름·시장)은 검색·관심·상세가 모두 같은 모양을
  /// 쓰므로 모델을 따로 만들지 않고 [SearchResult]를 재사용한다.
  SearchResult toModel() => SearchResult(
    symbol: symbolCode,
    name: stockName,
    marketName: stockExchangeNameKor,
  );
}
