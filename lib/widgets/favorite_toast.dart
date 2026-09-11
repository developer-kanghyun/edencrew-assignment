import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme.dart';

/// 관심 등록 · 해제 직후 화면 하단에 뜨는 알림.
class FavoriteToast extends StatelessWidget {
  const FavoriteToast({required this.registered, super.key});

  /// 등록이면 채운 별, 해제면 빈 별.
  final bool registered;

  static const double _height = 46;
  static const double _iconSize = 18;
  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          color: colors.borderSubtle,
          width: dimens.borderHairline,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            registered ? Icons.star_rounded : Icons.star_border_rounded,
            size: _iconSize,
            // 해제 토스트의 빈 별은 목록 행과 달리 textSecondary를 쓴다.
            // 토스트 배경이 밝아서 favoriteInactive로는 잘 안 보인다.
            color: registered ? colors.favoriteActive : colors.textSecondary,
          ),
          SizedBox(width: dimens.space2),
          Text(
            registered ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
            style: AppTextStyles.chip.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
