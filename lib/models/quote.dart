/// 등락 방향. 색상 토큰(priceUp / priceDown / priceFlat)을 고르는 데 쓴다.
enum PriceDirection { up, down, flat }

/// 실시간 시세 한 건.
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.accumulatedVolume,
    required this.listedShares,
  });

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int accumulatedVolume;
  final int listedShares;

  /// 전일 대비 등락액.
  ///
  /// 응답에도 등락액(`cv`) 필드가 있지만 부호 없는 절대값이고 방향은 별도 필드(`rf`)에
  /// 들어있다. 부호를 잘못 붙일 위험이 있어 현재가와 전일 종가의 차이로 직접 계산한다.
  int get change => currentPrice - previousClose;

  /// 전일 대비 등락률(%).
  double get changeRate =>
      previousClose == 0 ? 0 : change / previousClose * 100;

  PriceDirection get direction {
    if (change > 0) return PriceDirection.up;
    if (change < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }

  int get marketCap => currentPrice * listedShares;
}
