import 'package:flutter/material.dart';

import '../models/daily_price.dart';
import '../theme/theme.dart';

/// 일별 시세를 캔들로 그린다.
///
/// 패키지 대신 `CustomPainter`로 직접 그렸다. 필요한 것이 "봉 그리기" 하나뿐인데,
/// 캔들을 지원하는 패키지는 대체로 축·격자·툴팁까지 함께 들고 오고 색과 여백을
/// 시안에 맞추려면 결국 내부 설정과 씨름하게 된다. 직접 그리면 토큰 색을 그대로
/// 쓰고 봉 두께도 기간에 맞춰 조절할 수 있다.
class CandleChart extends StatelessWidget {
  const CandleChart({required this.prices, this.height = 200, super.key});

  /// 최신순으로 들어온다. 그릴 때는 왼쪽이 과거가 되도록 뒤집는다.
  final List<DailyPrice> prices;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CandlePainter(
          prices: prices.reversed.toList(),
          upColor: colors.chartLineUp,
          downColor: colors.chartLineDown,
          flatColor: colors.chartLineFlat,
          wickColor: colors.chartBaseline,
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.prices,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.wickColor,
  });

  final List<DailyPrice> prices;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final Color wickColor;

  /// 봉 사이 간격. 봉이 아주 얇아지면 간격도 줄인다.
  static const double _maxGap = 1;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    int highest = prices.first.highPrice;
    int lowest = prices.first.lowPrice;
    for (final DailyPrice price in prices) {
      if (price.highPrice > highest) highest = price.highPrice;
      if (price.lowPrice < lowest) lowest = price.lowPrice;
    }

    // 모든 값이 같으면 높이가 0이 되어 나눗셈이 깨진다.
    final double range = (highest - lowest).toDouble();
    double yOf(int value) => range == 0
        ? size.height / 2
        : size.height - (value - lowest) / range * size.height;

    final double slot = size.width / prices.length;
    final double gap = slot > 3 ? _maxGap : 0;
    final double bodyWidth = (slot - gap).clamp(1.0, slot);

    for (int i = 0; i < prices.length; i++) {
      final DailyPrice price = prices[i];
      final double centerX = slot * i + slot / 2;

      final Color color = switch (price.closePrice.compareTo(price.openPrice)) {
        > 0 => upColor,
        < 0 => downColor,
        _ => flatColor,
      };

      // 심지: 고가부터 저가까지 가는 얇은 세로선
      canvas.drawLine(
        Offset(centerX, yOf(price.highPrice)),
        Offset(centerX, yOf(price.lowPrice)),
        Paint()
          ..color = wickColor
          ..strokeWidth = 1,
      );

      // 몸통: 시가와 종가 사이. 두 값이 같으면 선 한 줄로 보이게 최소 높이를 준다.
      final double openY = yOf(price.openPrice);
      final double closeY = yOf(price.closePrice);
      final double top = openY < closeY ? openY : closeY;
      final double bodyHeight = (openY - closeY).abs().clamp(1.0, size.height);

      canvas.drawRect(
        Rect.fromLTWH(centerX - bodyWidth / 2, top, bodyWidth, bodyHeight),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) =>
      oldDelegate.prices != prices ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor;
}
