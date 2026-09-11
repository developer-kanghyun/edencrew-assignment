import 'package:flutter/widgets.dart';

import '../models/quote.dart';
import '../theme/theme.dart';

/// 등락 방향에 맞는 글자색. 국내 관행대로 상승이 빨강, 하락이 파랑이다.
///
/// 보합은 `textSecondary`와 hex가 같지만 Figma가 `price/flat/text`를 물려두었다.
/// 의미가 다른 토큰이므로 그대로 따른다.
/// 등락액만 있고 시세 객체가 없을 때 방향을 구한다.
/// 일별 시세 표는 앞뒤 종가 차이로 등락을 만들기 때문에 이 형태가 필요하다.
PriceDirection directionOf(int change) {
  if (change > 0) return PriceDirection.up;
  if (change < 0) return PriceDirection.down;
  return PriceDirection.flat;
}

Color priceTextColor(AppColors colors, PriceDirection direction) =>
    switch (direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
    };
