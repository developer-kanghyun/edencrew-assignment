import 'package:flutter/material.dart';

import '../state/detail_state.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import 'price_color.dart';

/// `일별 시세` 표. 컬럼은 날짜 · 종가 · 등락 · 거래량이다.
class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({required this.rows, super.key});

  final List<DailyPriceRow> rows;

  /// 시안 값. 날짜 칸만 폭이 고정이고 나머지 셋은 남은 공간을 똑같이 나눈다.
  static const double _dateColumnWidth = 46;
  static const double _rowHeight = 32;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '일별 시세',
          style: AppTextStyles.chip.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: context.dimens.space1),
        const _HeadRow(),
        for (final DailyPriceRow row in rows) _DataRow(row: row),
      ],
    );
  }
}

class _HeadRow extends StatelessWidget {
  const _HeadRow();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle style = AppTextStyles.rowSecondary.copyWith(
      color: colors.textSecondary,
    );

    return SizedBox(
      height: DailyPriceTable._rowHeight,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: DailyPriceTable._dateColumnWidth,
            child: Text('날짜', style: style),
          ),
          for (final String label in <String>['종가', '등락', '거래량']) ...<Widget>[
            SizedBox(width: context.dimens.space2),
            Expanded(
              child: Text(label, textAlign: TextAlign.right, style: style),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.row});

  final DailyPriceRow row;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final TextStyle base = AppTextStyles.rowSecondary;

    return Container(
      height: DailyPriceTable._rowHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: DailyPriceTable._dateColumnWidth,
            child: Text(
              row.price.monthDay,
              style: base.copyWith(color: colors.textSecondary),
            ),
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              formatThousands(row.price.closePrice),
              textAlign: TextAlign.right,
              style: base.copyWith(color: colors.textPrimary),
            ),
          ),
          SizedBox(width: dimens.space2),
          Expanded(child: _ChangeCell(change: row.change)),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              formatThousands(row.price.accumulatedTradingVolume),
              textAlign: TextAlign.right,
              style: base.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeCell extends StatelessWidget {
  const _ChangeCell({required this.change});

  /// 가장 오래된 줄은 비교할 전 거래일이 없어 null이다.
  final int? change;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextStyle style = AppTextStyles.rowSecondary;

    if (change == null) {
      // 시안에 없는 상태다. 빈칸으로 두면 열이 어긋나 보여 가운뎃줄로 채운다.
      return Text(
        '–',
        textAlign: TextAlign.right,
        style: style.copyWith(color: colors.textTertiary),
      );
    }

    return Text(
      formatChange(change!),
      textAlign: TextAlign.right,
      style: style.copyWith(
        color: priceTextColor(colors, directionOf(change!)),
      ),
    );
  }
}
