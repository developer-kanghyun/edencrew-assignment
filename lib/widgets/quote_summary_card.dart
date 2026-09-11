import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';

/// 시가 · 고가 · 저가 · 거래량 · 시가총액 요약.
///
/// 시안이 위 3칸 / 아래 2칸으로 나눠 놓아서 그대로 두 줄로 만든다.
class QuoteSummaryCard extends StatelessWidget {
  const QuoteSummaryCard({required this.quote, super.key});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _Cell(label: '시가', value: formatThousands(quote.open))),
            SizedBox(width: dimens.space2),
            Expanded(child: _Cell(label: '고가', value: formatThousands(quote.high))),
            SizedBox(width: dimens.space2),
            Expanded(child: _Cell(label: '저가', value: formatThousands(quote.low))),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: <Widget>[
            Expanded(
              child: _Cell(
                label: '거래량',
                value: formatVolume(quote.accumulatedVolume),
              ),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _Cell(
                label: '시가총액',
                value: formatMarketCap(quote.marketCap),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  /// 시안 값. space 토큰에 없는 9 / 10 / 3이다.
  static const double _verticalPadding = 9;
  static const double _horizontalPadding = 10;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: _verticalPadding,
        horizontal: _horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(context.dimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.rowSecondary.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: _gap),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.rowPrimary.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
