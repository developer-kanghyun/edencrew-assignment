import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/quote.dart';
import 'package:edencrew_assignment_starter/screens/watchlist_screen.dart';
import 'package:edencrew_assignment_starter/state/app_scope.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late StockRepository repository;
  late FavoritesState favorites;

  setUp(() {
    repository = fakeRepository();
    favorites = FavoritesState(repository);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        favorites: favorites,
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: WatchlistScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void addSamsung() => favorites.toggle(
    symbol: '005930',
    name: '삼성전자',
    marketName: '코스피',
  );

  testWidgets('관심종목이 없으면 빈 상태를 보여준다', (WidgetTester tester) async {
    await pumpScreen(tester);

    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(find.text('검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.'), findsOneWidget);
  });

  testWidgets('빈 상태에서도 헤더는 그대로 있다', (WidgetTester tester) async {
    await pumpScreen(tester);

    expect(find.text('관심'), findsOneWidget);
    expect(find.text('가나다순'), findsOneWidget);
  });

  testWidgets('관심종목이 있으면 종목명과 코드·시장을 보여준다', (WidgetTester tester) async {
    addSamsung();
    await pumpScreen(tester);

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.text('관심 종목이 없습니다'), findsNothing);
  });

  testWidgets('시세가 도착하면 현재가와 등락을 보여준다', (WidgetTester tester) async {
    addSamsung();
    favorites.applyQuotes(<String, Quote>{
      '005930': const Quote(
        symbol: '005930',
        currentPrice: 179700,
        previousClose: 180100,
        open: 180000,
        high: 181000,
        low: 179000,
        accumulatedVolume: 1000,
        listedShares: 100,
      ),
    });
    await pumpScreen(tester);

    expect(find.text('179,700'), findsOneWidget);
    expect(find.text('-400 (-0.22%)'), findsOneWidget);
  });

  testWidgets('시세를 못 받은 행은 등락을 표시하지 않는다', (WidgetTester tester) async {
    addSamsung();
    await pumpScreen(tester);

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  group('정렬 바텀시트', () {
    testWidgets('정렬 칩을 누르면 열린다', (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('가나다순'));
      await tester.pumpAndSettle();

      expect(find.text('정렬'), findsOneWidget);
      expect(find.text('현재가순'), findsOneWidget);
      expect(find.text('등락률순'), findsOneWidget);
    });

    testWidgets('선택하면 시트가 닫히고 헤더 칩이 바뀐다', (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('가나다순'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('현재가순'));
      await tester.pumpAndSettle();

      expect(find.text('정렬'), findsNothing);
      expect(find.text('현재가순'), findsOneWidget);
      expect(favorites.sortOrder, SortOrder.price);
    });

    testWidgets('현재 기준에 체크가 붙는다', (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('가나다순'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
