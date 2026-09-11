import 'package:flutter/material.dart';

import '../models/favorite_stock.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import 'price_color.dart';

/// 관심 화면의 목록 한 줄.
///
/// 시세를 아직 받지 못했으면(`quote == null`) 오른쪽을 스켈레톤으로 그린다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({required this.stock, this.onTap, super.key});

  final FavoriteStock stock;
  final VoidCallback? onTap;

  /// 종목명과 코드 사이 간격. space 토큰의 최솟값이 4라 시안 값 2를 그대로 쓴다.
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space3,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: _Identity(stock: stock)),
            SizedBox(width: dimens.space3),
            if (stock.quote == null)
              const _QuoteSkeleton()
            else
              _QuotePrice(stock: stock),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.stock});

  final FavoriteStock stock;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // 긴 종목명은 시안에 정의가 없다. 줄바꿈 대신 말줄임으로 처리해
        // 행 높이가 종목마다 달라지지 않게 한다.
        Text(
          stock.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.rowPrimary.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: WatchlistRow._lineGap),
        Text(
          formatSymbolAndMarket(stock.symbol, stock.marketName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.rowSecondary.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuotePrice extends StatelessWidget {
  const _QuotePrice({required this.stock});

  final FavoriteStock stock;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final quote = stock.quote!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          formatThousands(quote.currentPrice),
          style: AppTextStyles.rowPrimary.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: WatchlistRow._lineGap),
        Text(
          formatChangeSummary(quote),
          style: AppTextStyles.rowSecondary.copyWith(
            color: priceTextColor(colors, quote.direction),
          ),
        ),
      ],
    );
  }
}

/// 시세 도착 전 자리를 잡아두는 회색 막대. 크기는 시안 값 그대로다.
class _QuoteSkeleton extends StatelessWidget {
  const _QuoteSkeleton();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(dimens.radiusSm),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        bar(64, 16),
        const SizedBox(height: WatchlistRow._lineGap),
        bar(48, 12),
      ],
    );
  }
}
