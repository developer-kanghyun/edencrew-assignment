import '../../models/search_result.dart';

/// 검색 자동완성 응답의 `items` 한 건. 네이버가 준 필드명을 그대로 쓴다.
///
/// 응답에는 해외 주식과 지수도 섞여 오고, 지수는 `nationCode`가 null이다.
/// 그래서 국내 주식에서만 채워지는 필드는 nullable로 받는다.
class SearchItemDto {
  const SearchItemDto({
    required this.code,
    required this.name,
    this.typeName,
    this.nationCode,
    this.category,
  });

  factory SearchItemDto.fromJson(Map<String, dynamic> json) {
    return SearchItemDto(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      typeName: json['typeName'] as String?,
      nationCode: json['nationCode'] as String?,
      category: json['category'] as String?,
    );
  }

  /// 종목코드. 국내 주식은 6자리 숫자, 해외는 `AAPL`, 지수는 `KOSPI` 형태다.
  final String code;
  final String name;

  /// 국내 주식이면 `코스피` 또는 `코스닥`이 들어온다.
  final String? typeName;

  /// 국내는 `KOR`, 해외는 `USA`·`JPN`, 지수는 null이다.
  final String? nationCode;

  /// `stock` 또는 `index`.
  final String? category;

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  /// 이 과제가 다루는 대상인지 판단한다.
  /// 국적이 한국이고, 지수가 아닌 주식이며, 6자리 종목코드여야 한다.
  bool get isDomesticStock =>
      nationCode == 'KOR' &&
      category == 'stock' &&
      _sixDigits.hasMatch(code);

  SearchResult toModel() => SearchResult(
    symbol: code,
    name: name,
    marketName: typeName ?? '',
  );
}
