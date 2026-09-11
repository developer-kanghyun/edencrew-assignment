import 'package:flutter/material.dart';

import '../models/chart_period.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';

/// 상세 화면의 기간 탭. 선택된 칩만 accent 색을 쓴다.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  /// 시안 값. space 토큰에 없다.
  static const double _chipHeight = 28;
  static const double _chipVerticalPadding = 5;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Row(
      children: <Widget>[
        for (final ChartPeriod period in ChartPeriod.values) ...<Widget>[
          if (period != ChartPeriod.values.first)
            SizedBox(width: dimens.space1),
          Expanded(
            child: _Chip(
              label: period.label,
              selected: period == selected,
              onTap: () => onSelected(period),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: PeriodTabs._chipHeight,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: PeriodTabs._chipVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accentBg : null,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Text(
          label,
          style: AppTextStyles.chip.copyWith(
            fontWeight: FontWeight.w400,
            color: selected ? colors.accentDefault : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
