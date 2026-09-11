import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme.dart';

/// 관심 / 검색을 오가는 하단 탭 바.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// 아이콘과 라벨 사이 간격. space 토큰에 없는 시안 값이다.
  static const double _iconLabelGap = 3;

  /// 탭 아이콘 크기. icon 토큰은 16과 20뿐이라 시안 값 22를 그대로 쓴다.
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dimens.space2),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavItem(
                  icon: Icons.star_rounded,
                  label: '관심',
                  selected: currentIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.search_rounded,
                  label: '검색',
                  selected: currentIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = selected ? colors.navActive : colors.navInactive;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.dimens.space1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppBottomNav._iconSize, color: color),
            const SizedBox(height: AppBottomNav._iconLabelGap),
            Text(
              label,
              style: AppTextStyles.rowSecondary.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
