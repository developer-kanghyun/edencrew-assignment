/// 검색 자동완성 결과 한 건.
class SearchResult {
  const SearchResult({
    required this.symbol,
    required this.name,
    required this.marketName,
  });

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피`
  final String marketName;

  /// 앱 전체에서 종목을 가리키는 키.
  /// 자동완성 응답에는 해외 종목도 섞여 오므로 국내 종목임을 접두사로 구분한다.
  String get canonicalId => 'domestic:$symbol';
}
