import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/screens/main_screen.dart';
import 'package:edencrew_assignment_starter/screens/watchlist_screen.dart';
import 'package:edencrew_assignment_starter/state/app_scope.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:edencrew_assignment_starter/state/search_state.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/widgets/search_result_row.dart';
import 'package:edencrew_assignment_starter/widgets/watchlist_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

/// 과제 필수 4번 "상태 동기화"를 실제 화면 조작으로 확인한다.
///
/// 관심 화면과 검색 화면을 한 앱에 띄워놓고 탭을 오가며, 한쪽에서 바꾼 별표가
/// 다른 쪽에 그대로 나타나는지 본다.
///
/// 찾는 범위를 화면별로 좁히는 이유가 두 가지 있다. 하단 탭 바가 같은 별 아이콘을
/// 쓰고, `IndexedStack`이 보이지 않는 탭의 위젯도 트리에 남겨두기 때문이다.
void main() {
  late StockRepository repository;
  late FavoritesState favorites;

  setUp(() {
    repository = fakeRepository(
      onRequest: (http.Request request) async {
        if (request.url.host.contains('polling')) {
          return jsonResponse(<String, dynamic>{
            'resultCode': 'success',
            'result': <String, dynamic>{'areas': <dynamic>[]},
          });
        }
        return autocompleteResponse(<String, String>{'005930': '삼성전자'});
      },
    );
    favorites = FavoritesState(repository);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        favorites: favorites,
        repository: repository,
        child: MaterialApp(theme: AppTheme.dark, home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToSearchTab(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(InkWell, '검색').last);
    await tester.pumpAndSettle();
  }

  Future<void> goToWatchlistTab(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(InkWell, '관심').last);
    await tester.pumpAndSettle();
  }

  Future<void> searchSamsung(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pump(SearchState.debounce + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  /// 토스트가 사라질 때까지 흘려보낸다.
  Future<void> letToastPass(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  // 검색 결과 행 안의 별만 고른다. 탭 바와 토스트의 별을 배제한다.
  Finder searchRowStar({required bool filled}) => find.descendant(
    of: find.byType(SearchResultRow),
    matching: find.byIcon(
      filled ? Icons.star_rounded : Icons.star_border_rounded,
    ),
  );

  Finder watchlistEmptyText() => find.descendant(
    of: find.byType(WatchlistScreen),
    matching: find.text('관심 종목이 없습니다'),
  );

  Finder watchlistRowFor(String label) => find.descendant(
    of: find.byType(WatchlistRow),
    matching: find.text(label),
  );

  testWidgets('검색 화면에서 등록하면 관심 목록에 나타난다', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(watchlistEmptyText(), findsOneWidget);

    await goToSearchTab(tester);
    await searchSamsung(tester);
    await tester.tap(searchRowStar(filled: false));
    await letToastPass(tester);

    await goToWatchlistTab(tester);

    expect(watchlistEmptyText(), findsNothing);
    expect(watchlistRowFor('005930 · 코스피'), findsOneWidget);
  });

  testWidgets('관심 상태를 해제하면 검색 결과의 별도 빈 별이 된다', (
    WidgetTester tester,
  ) async {
    favorites.toggle(symbol: '005930', name: '삼성전자', marketName: '코스피');
    await pumpApp(tester);

    await goToSearchTab(tester);
    await searchSamsung(tester);
    expect(searchRowStar(filled: true), findsOneWidget);

    // 관심 화면에서 해제한 것과 같은 경로다.
    favorites.toggle(symbol: '005930', name: '삼성전자', marketName: '코스피');
    await tester.pumpAndSettle();

    expect(searchRowStar(filled: true), findsNothing);
    expect(searchRowStar(filled: false), findsOneWidget);
  });

  testWidgets('검색 직후에도 이미 등록된 종목은 채운 별로 보인다', (WidgetTester tester) async {
    favorites.toggle(symbol: '005930', name: '삼성전자', marketName: '코스피');
    await pumpApp(tester);

    await goToSearchTab(tester);
    await searchSamsung(tester);

    expect(searchRowStar(filled: true), findsOneWidget);
    expect(searchRowStar(filled: false), findsNothing);
  });

  testWidgets('등록과 해제를 반복해도 두 화면이 계속 일치한다', (WidgetTester tester) async {
    await pumpApp(tester);
    await goToSearchTab(tester);
    await searchSamsung(tester);

    for (int round = 1; round <= 3; round++) {
      await tester.tap(searchRowStar(filled: false));
      await letToastPass(tester);
      await goToWatchlistTab(tester);
      expect(
        watchlistRowFor('005930 · 코스피'),
        findsOneWidget,
        reason: '$round회차 등록',
      );

      await goToSearchTab(tester);
      await tester.tap(searchRowStar(filled: true));
      await letToastPass(tester);
      await goToWatchlistTab(tester);
      expect(watchlistEmptyText(), findsOneWidget, reason: '$round회차 해제');

      await goToSearchTab(tester);
    }
  });

  testWidgets('탭을 오가도 검색어와 결과가 남아 있다', (WidgetTester tester) async {
    await pumpApp(tester);
    await goToSearchTab(tester);
    await searchSamsung(tester);

    await goToWatchlistTab(tester);
    await goToSearchTab(tester);

    expect(find.text('삼성'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SearchResultRow),
        matching: find.text('005930 · 코스피'),
      ),
      findsOneWidget,
    );
  });
}
