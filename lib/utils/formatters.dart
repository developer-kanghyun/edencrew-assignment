import '../models/quote.dart';

/// 천 단위 쉼표를 넣는다. `179700` → `179,700`
///
/// 보통은 intl 패키지의 NumberFormat을 쓰지만, 이 앱이 intl에서 필요한 건
/// 이 기능 하나뿐이라 패키지를 들이지 않고 직접 만들었다.
/// 대신 경계값은 `test/formatters_test.dart`에서 확인한다.
String formatThousands(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return value < 0 ? '-$buffer' : buffer.toString();
}

/// 등락액. 시안대로 오를 때만 `+`를 붙이고 보합은 부호가 없다.
/// `+9,500` / `-400` / `0`
String formatChange(int change) {
  if (change == 0) return '0';
  final String sign = change > 0 ? '+' : '-';
  return '$sign${formatThousands(change.abs())}';
}

/// 등락률. `+2.36%` / `-0.22%` / `0.00%`
String formatChangeRate(double rate) {
  if (rate == 0) return '0.00%';
  final String sign = rate > 0 ? '+' : '-';
  return '$sign${rate.abs().toStringAsFixed(2)}%';
}

/// 목록 행에 들어가는 `-400 (-0.22%)` 형태.
String formatChangeSummary(Quote quote) =>
    '${formatChange(quote.change)} (${formatChangeRate(quote.changeRate)})';

/// `005930 · 코스피`
String formatSymbolAndMarket(String symbol, String marketName) =>
    '$symbol · $marketName';
