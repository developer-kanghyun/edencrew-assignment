import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import '../utils/highlight.dart';

/// 검색 결과 한 줄. 종목명에서 검색어와 겹치는 부분을 다른 색으로 칠한다.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.result,
    required this.query,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
    super.key,
  });

  final SearchResult result;
  final String query;

  /// 별표 상태는 이 위젯이 갖지 않고 밖에서 받는다.
  /// 출처는 `FavoritesState` 하나뿐이라 화면 사이에서 어긋날 수 없다.
  final bool isFavorite;

  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  static const double _lineGap = 2;
  static const double _starSize = 22;

  /// 별 아이콘은 22pt라 그대로 두면 손가락으로 누르기 어렵다.
  /// 아이콘 좌우로 여백을 붙여 누를 수 있는 범위를 44pt로 넓혔다.
  /// 그만큼 행의 오른쪽 여백에서 빼서 **아이콘이 보이는 위치는 시안 그대로**다.
  static const double _starTapPadding = 11;
  static const double _starTapWidth = _starSize + _starTapPadding * 2;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          dimens.space4,
          dimens.space3,
          dimens.space4 - _starTapPadding,
          dimens.space3,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        for (final HighlightSegment segment
                            in splitHighlight(result.name, query))
                          TextSpan(
                            text: segment.text,
                            style: TextStyle(
                              color: segment.matched
                                  ? colors.searchHighlight
                                  : colors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowPrimary,
                  ),
                  const SizedBox(height: _lineGap),
                  Text(
                    formatSymbolAndMarket(result.symbol, result.marketName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowSecondary.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: dimens.space3 - _starTapPadding),
            GestureDetector(
              onTap: onToggleFavorite,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: _starTapWidth,
                child: Center(
                  child: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    size: _starSize,
                    color: isFavorite
                        ? colors.favoriteActive
                        : colors.favoriteInactive,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
