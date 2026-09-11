import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme.dart';

/// 목록 자리에 들어가는 빈 상태.
///
/// 관심 화면과 검색 화면이 같은 레이아웃을 쓴다 — 아이콘 40, 간격 12,
/// 제목(`textSecondary`), 간격 12, 안내 문구(`textTertiary`, 가운데 정렬).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: _iconSize, color: colors.textTertiary),
            SizedBox(height: dimens.space3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.rowSecondary.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
