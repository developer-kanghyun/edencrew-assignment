import 'package:flutter/material.dart';

import '../models/favorite_stock.dart';
import '../state/app_scope.dart';
import '../state/favorites_state.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../widgets/watchlist_row.dart';

/// `01 · 관심` 화면. 목록, 빈 상태, 정렬 바텀시트가 모두 여기에 있다.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    // 첫 프레임을 그린 뒤에 시세를 요청한다. 도착 전까지 각 행은 스켈레톤이다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).favorites.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final FavoritesState favorites = AppScope.of(context).favorites;

    return ListenableBuilder(
      listenable: favorites,
      builder: (BuildContext context, _) {
        return Column(
          children: <Widget>[
            _Header(favorites: favorites),
            if (favorites.errorMessage != null)
              _ErrorBanner(message: favorites.errorMessage!),
            Expanded(
              child: favorites.isEmpty
                  ? const _EmptyState()
                  : _StockList(favorites: favorites),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.favorites});

  final FavoritesState favorites;

  static const double _utilIconSize = 20;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      child: Row(
        children: <Widget>[
          Text(
            '관심',
            style: AppTextStyles.screenTitle.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => _openSortSheet(context, favorites),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  favorites.sortOrder.label,
                  style: AppTextStyles.chip.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: _utilIconSize,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          SizedBox(width: dimens.space4),
          InkWell(
            // 이미 조회 중이면 눌러도 중복 요청하지 않는다.
            onTap: favorites.isRefreshing ? null : favorites.refresh,
            child: Icon(
              Icons.refresh_rounded,
              size: _utilIconSize,
              color: favorites.isRefreshing
                  ? colors.textDisabled
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({required this.favorites});

  final FavoritesState favorites;

  @override
  Widget build(BuildContext context) {
    final List<FavoriteStock> stocks = favorites.stocks;

    return RefreshIndicator(
      onRefresh: favorites.refresh,
      child: ListView.builder(
        itemCount: stocks.length,
        itemBuilder: (BuildContext context, int index) =>
            WatchlistRow(stock: stocks[index]),
      ),
    );
  }
}

/// `01 · 관심_empty`. 헤더와 탭바는 그대로 두고 목록 자리만 바뀐다.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const double _starSize = 40;

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
            Icon(
              Icons.star_border_rounded,
              size: _starSize,
              color: colors.textTertiary,
            ),
            SizedBox(height: dimens.space3),
            Text(
              '관심 종목이 없습니다',
              style: AppTextStyles.screenTitle.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: dimens.space3),
            Text(
              '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
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

/// 시안에 없는 상태다. 시세 조회가 실패해도 목록 자체는 보여야 해서
/// 화면을 가리지 않는 얇은 띠로 알린다.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space2,
      ),
      color: colors.surfaceSunken,
      child: Text(
        message,
        style: AppTextStyles.rowSecondary.copyWith(
          color: colors.feedbackWarning,
        ),
      ),
    );
  }
}

/// `01 · 관심_sort`의 정렬 바텀시트.
Future<void> _openSortSheet(
  BuildContext context,
  FavoritesState favorites,
) async {
  final AppColors colors = context.colors;
  final AppDimens dimens = context.dimens;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: colors.scrim,
    builder: (BuildContext sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceOverlay,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(dimens.radiusLg + dimens.space1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: _SortSheetMetrics.titleHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _SortSheetMetrics.horizontalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '정렬',
                      style: AppTextStyles.screenTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              for (final SortOrder order in SortOrder.values)
                _SortOption(
                  order: order,
                  selected: order == favorites.sortOrder,
                  onTap: () {
                    favorites.setSortOrder(order);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

abstract final class _SortSheetMetrics {
  /// 시안 값. space 토큰(최대 24)으로는 표현되지 않는 높이라 그대로 쓴다.
  static const double titleHeight = 64;
  static const double optionHeight = 56;
  static const double horizontalPadding = 24;
  static const double checkIconSize = 24;
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final SortOrder order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: _SortSheetMetrics.optionHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _SortSheetMetrics.horizontalPadding,
          ),
          child: Row(
            children: <Widget>[
              Text(
                order.label,
                style: AppTextStyles.rowPrimary.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: _SortSheetMetrics.checkIconSize,
                  color: colors.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
