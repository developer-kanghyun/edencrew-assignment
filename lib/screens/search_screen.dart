import 'dart:async';

import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../state/app_scope.dart';
import '../state/favorites_state.dart';
import '../state/search_state.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_toast.dart';
import '../widgets/search_field.dart';
import '../widgets/search_result_row.dart';

/// `02 · 검색` 화면. 결과 목록, 초기 빈 상태, 결과 없음, 토스트가 여기에 있다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  SearchState? _search;

  /// 토스트가 떠 있으면 등록(true) / 해제(false), 없으면 null.
  bool? _toastRegistered;
  Timer? _toastTimer;

  /// 시안에 노출 시간이 없어 직접 정했다. 문구를 읽기에 충분하면서
  /// 다음 조작을 방해하지 않는 길이로 2초를 골랐다.
  static const Duration _toastDuration = Duration(seconds: 2);

  /// 토스트와 탭 바 사이 간격 (시안 값).
  static const double _toastBottomGap = 12;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _search ??= SearchState(AppScope.of(context).repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    _toastTimer?.cancel();
    _search?.dispose();
    super.dispose();
  }

  void _onToggleFavorite(SearchResult result) {
    final FavoritesState favorites = AppScope.of(context).favorites;
    final bool willRegister = !favorites.isFavorite(result.symbol);

    favorites.toggle(
      symbol: result.symbol,
      name: result.name,
      marketName: result.marketName,
    );

    // 연달아 누르면 이전 토스트를 교체한다. 쌓이면 화면을 가린다.
    _toastTimer?.cancel();
    setState(() => _toastRegistered = willRegister);
    _toastTimer = Timer(_toastDuration, () {
      if (mounted) setState(() => _toastRegistered = null);
    });
  }

  void _onClear() {
    _controller.clear();
    _search!.clear();
  }

  @override
  Widget build(BuildContext context) {
    final SearchState search = _search!;
    final FavoritesState favorites = AppScope.of(context).favorites;

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            SearchField(
              controller: _controller,
              onChanged: search.onQueryChanged,
              onClear: _onClear,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[search, favorites]),
                builder: (BuildContext context, _) =>
                    _Body(search: search, onToggleFavorite: _onToggleFavorite),
              ),
            ),
          ],
        ),
        Positioned(
          left: context.dimens.space4,
          right: context.dimens.space4,
          bottom: _toastBottomGap,
          child: _ToastSlot(registered: _toastRegistered),
        ),
      ],
    );
  }
}

/// 토스트가 뜨고 사라지는 동작. 시안에 정의가 없어 직접 정했다.
/// 갑자기 나타났다 사라지면 눈에 거슬려서 아래에서 올라오며 서서히 나타난다.
class _ToastSlot extends StatelessWidget {
  const _ToastSlot({required this.registered});

  final bool? registered;

  @override
  Widget build(BuildContext context) {
    // 숨길 때 투명도만 0으로 두면 위젯이 트리에 남아 화면 낭독기가 읽어버린다.
    // AnimatedSwitcher는 사라진 뒤 트리에서 빼준다.
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: registered == null
            ? const SizedBox.shrink()
            : FavoriteToast(
                key: ValueKey<bool>(registered!),
                registered: registered!,
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.search, required this.onToggleFavorite});

  final SearchState search;
  final ValueChanged<SearchResult> onToggleFavorite;

  /// 검색어가 아주 길면 빈 상태 문구가 화면을 덮는다. 시안에 정의가 없어
  /// 문구 안에서만 잘라 보여주기로 했다. 입력값 자체는 건드리지 않는다.
  static const int _queryPreviewLimit = 20;

  String get _queryPreview {
    final String query = search.query.trim();
    return query.length <= _queryPreviewLimit
        ? query
        : '${query.substring(0, _queryPreviewLimit)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (search.errorMessage != null) {
      return _ErrorState(message: search.errorMessage!);
    }

    if (search.isBeforeSearch) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }

    if (search.isLoading) {
      return const _LoadingState();
    }

    if (search.hasNoResult) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        description: "'$_queryPreview'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    final FavoritesState favorites = AppScope.of(context).favorites;

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: search.results.length,
      itemBuilder: (BuildContext context, int index) {
        final SearchResult result = search.results[index];
        return SearchResultRow(
          result: result,
          query: search.query,
          // 별표는 화면이 들고 있지 않고 매번 FavoritesState에 묻는다.
          isFavorite: favorites.isFavorite(result.symbol),
          onToggleFavorite: () => onToggleFavorite(result),
          onTap: () {},
        );
      },
    );
  }
}

/// 검색 중 표시. 시안에 없는 상태라 목록 자리에 조용히 넣었다.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: context.dimens.iconMd,
        height: context.dimens.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dimens.space4),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.rowSecondary.copyWith(
            color: context.colors.feedbackWarning,
          ),
        ),
      ),
    );
  }
}
