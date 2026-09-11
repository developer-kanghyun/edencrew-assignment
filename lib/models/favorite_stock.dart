import 'quote.dart';

/// 관심 목록에 담긴 종목 하나.
class FavoriteStock {
  const FavoriteStock({
    required this.symbol,
    required this.name,
    required this.marketName,
    this.quote,
  });

  final String symbol;
  final String name;
  final String marketName;

  /// 아직 시세를 받지 못했으면 null. 이때 목록에서 스켈레톤으로 표시한다.
  final Quote? quote;

  String get canonicalId => 'domestic:$symbol';

  FavoriteStock copyWith({Quote? quote}) => FavoriteStock(
    symbol: symbol,
    name: name,
    marketName: marketName,
    quote: quote ?? this.quote,
  );
}
