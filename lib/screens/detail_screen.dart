import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../state/app_scope.dart';
import '../state/detail_state.dart';
import '../state/favorites_state.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import '../widgets/candle_chart.dart';
import '../widgets/daily_price_table.dart';
import '../widgets/period_tabs.dart';
import '../widgets/price_color.dart';
import '../widgets/quote_summary_card.dart';

/// `03 · 종목상세` 화면.
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    required this.symbol,
    required this.name,
    required this.marketName,
    super.key,
  });

  final String symbol;
  final String name;
  final String marketName;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  DetailState? _detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detail != null) return;
    _detail = DetailState(AppScope.of(context).repository, symbol: widget.symbol)
      ..load();
  }

  @override
  void dispose() {
    _detail?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DetailState detail = _detail!;
    final FavoritesState favorites = AppScope.of(context).favorites;

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _AppBar(
              name: widget.name,
              marketName: widget.marketName,
              symbol: widget.symbol,
              favorites: favorites,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: detail,
                builder: (BuildContext context, _) => _Body(detail: detail),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.name,
    required this.marketName,
    required this.symbol,
    required this.favorites,
  });

  final String name;
  final String marketName;
  final String symbol;
  final FavoritesState favorites;

  static const double _backIconSize = 20;
  static const double _starSize = 22;
  static const double _starTapPadding = 11;
  static const double _identityGap = 1;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space2 + 2,
        dimens.space4 - _starTapPadding,
        dimens.space2 + 2,
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_rounded,
              size: _backIconSize,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(width: dimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.rowPrimary.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: _identityGap),
                Text(
                  formatSymbolAndMarket(symbol, marketName),
                  style: AppTextStyles.rowSecondary.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: favorites,
            builder: (BuildContext context, _) {
              final bool isFavorite = favorites.isFavorite(symbol);
              return GestureDetector(
                onTap: () => favorites.toggle(
                  symbol: symbol,
                  name: name,
                  marketName: marketName,
                ),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: _starSize + _starTapPadding * 2,
                  child: Center(
                    child: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: _starSize,
                      color: isFavorite
                          ? colors.favoriteActive
                          : colors.favoriteInactive,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final DetailState detail;

  /// 시안 값. Body의 위아래 여백과 두 묶음 사이 간격이다.
  static const double _bodyTopPadding = 14;
  static const double _sectionGap = 24;
  static const double _priceGap = 16;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final Quote? quote = detail.quote;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        _bodyTopPadding,
        dimens.space4,
        dimens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (detail.errorMessage != null)
            _ErrorText(message: detail.errorMessage!),
          if (quote != null) ...<Widget>[
            _CurrentPrice(quote: quote),
            const SizedBox(height: _priceGap),
          ],
          PeriodTabs(
            selected: detail.period,
            onSelected: detail.changePeriod,
          ),
          const SizedBox(height: _priceGap),
          _ChartArea(detail: detail),
          if (quote != null) ...<Widget>[
            const SizedBox(height: _priceGap),
            QuoteSummaryCard(quote: quote),
          ],
          const SizedBox(height: _sectionGap),
          DailyPriceTable(rows: toDailyRows(detail.dailyPrices)),
        ],
      ),
    );
  }
}

class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.quote});

  final Quote quote;

  /// 시안 값. 현재가는 30 / Bold / 행간 36 / 자간 -0.4로 이 화면에만 나온다.
  static const double _priceFontSize = 30;
  static const double _priceLineHeight = 36;
  static const double _priceTracking = -0.4;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          formatThousands(quote.currentPrice),
          style: AppTextStyles.screenTitle.copyWith(
            fontSize: _priceFontSize,
            height: _priceLineHeight / _priceFontSize,
            letterSpacing: _priceTracking,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(width: context.dimens.space2),
        Padding(
          // 큰 숫자의 밑선에 맞춘다.
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            formatChangeWithArrow(quote),
            style: AppTextStyles.rowPrimary.copyWith(
              color: priceTextColor(colors, quote.direction),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartArea extends StatelessWidget {
  const _ChartArea({required this.detail});

  final DetailState detail;

  static const double _chartHeight = 200;

  @override
  Widget build(BuildContext context) {
    if (detail.dailyPrices.isEmpty) {
      return SizedBox(
        height: _chartHeight,
        child: Center(
          child: detail.isLoadingChart
              ? SizedBox(
                  width: context.dimens.iconMd,
                  height: context.dimens.iconMd,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.textTertiary,
                  ),
                )
              : Text(
                  '차트를 불러오지 못했습니다',
                  style: AppTextStyles.rowSecondary.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
        ),
      );
    }

    // 기간을 바꾸는 동안 이전 차트를 흐리게 남긴다. 비워버리면 화면이 덜컥거린다.
    return Opacity(
      opacity: detail.isLoadingChart ? 0.4 : 1,
      child: CandleChart(prices: detail.dailyPrices, height: _chartHeight),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space3),
      child: Text(
        message,
        style: AppTextStyles.rowSecondary.copyWith(
          color: context.colors.feedbackWarning,
        ),
      ),
    );
  }
}
