import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Figma 텍스트 레이어에서 측정한 실제 값입니다.
///
/// `app_typography.dart`는 서체와 굵기만 토큰으로 두고 크기는 화면에서 직접
/// 확인하라고 안내합니다. 그 말대로 Figma API로 레이어마다 값을 읽어 왔는데,
/// 같은 조합이 화면 여러 곳에 반복돼서 한곳에 모았습니다. 임의로 만든 타입
/// 스케일이 아니라 시안에서 그대로 옮긴 값입니다.
///
/// 색은 쓰는 곳마다 달라서(같은 크기라도 textPrimary / textSecondary / 등락색)
/// 여기서 정하지 않고 `copyWith(color:)`로 붙입니다.
abstract final class AppTextStyles {
  /// 화면 제목과 바텀시트 제목. 19 / Bold / 행간 22 / 자간 -0.2
  static const TextStyle screenTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 19,
    fontWeight: AppTypography.bold,
    height: 22 / 19,
    letterSpacing: -0.2,
  );

  /// 헤더의 정렬 칩. 13 / Bold / 행간 18
  static const TextStyle chip = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: AppTypography.bold,
    height: 18 / 13,
  );

  /// 목록 행의 종목명과 현재가, 바텀시트 항목. 15 / Medium / 행간 20 / 자간 -0.1
  static const TextStyle rowPrimary = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 15,
    fontWeight: AppTypography.medium,
    height: 20 / 15,
    letterSpacing: -0.1,
  );

  /// 종목코드·시장, 등락, 탭 라벨, 안내 문구. 11 / Regular / 행간 14
  static const TextStyle rowSecondary = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: AppTypography.regular,
    height: 14 / 11,
  );
}
