import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/screens/search_screen.dart';
import 'package:edencrew_assignment_starter/state/app_scope.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:edencrew_assignment_starter/state/search_state.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

void main() {
  late StockRepository repository;
  late FavoritesState favorites;

  void setUpWith(Map<String, String> stocks) {
    repository = fakeRepository(
      onRequest: (http.Request request) async {
        // 시세 조회는 빈 응답, 자동완성은 주어진 종목 목록으로 답한다.
        if (request.url.host.contains('polling')) {
          return jsonResponse(<String, dynamic>{
            'resultCode': 'success',
            'result': <String, dynamic>{'areas': <dynamic>[]},
          });
        }
        return autocompleteResponse(stocks);
      },
    );
    favorites = FavoritesState(repository);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        favorites: favorites,
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: SearchScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  /// 검색어를 입력하고 디바운스와 응답을 흘려보낸다.
  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(SearchState.debounce + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('검색 전에는 초기 빈 상태를 보여준다', (WidgetTester tester) async {
    setUpWith(<String, String>{});
    await pumpScreen(tester);

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(find.text('종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.'), findsOneWidget);
  });

  testWidgets('입력창에 안내 문구가 있다', (WidgetTester tester) async {
    setUpWith(<String, String>{});
    await pumpScreen(tester);

    expect(find.text('종목명 또는 종목코드'), findsOneWidget);
  });

  testWidgets('검색하면 결과를 보여준다', (WidgetTester tester) async {
    setUpWith(<String, String>{'005930': '삼성전자', '005935': '삼성전자우'});
    await pumpScreen(tester);
    await search(tester, '삼성');

    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.text('005935 · 코스피'), findsOneWidget);
    expect(find.text('종목을 검색해 보세요'), findsNothing);
  });

  testWidgets('결과가 없으면 검색어를 넣은 문구를 보여준다', (WidgetTester tester) async {
    setUpWith(<String, String>{});
    await pumpScreen(tester);
    await search(tester, 'ㄱㄴㄷㄹ');

    expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    expect(
      find.text("'ㄱㄴㄷㄹ'와\n일치하는 검색 결과를 찾지 못했습니다."),
      findsOneWidget,
    );
  });

  testWidgets('아주 긴 검색어는 문구 안에서 잘라 보여준다', (WidgetTester tester) async {
    setUpWith(<String, String>{});
    await pumpScreen(tester);
    await search(tester, '가' * 50);

    // 문구 안에서만 자른다. 입력창은 입력한 그대로 들고 있어야 한다.
    expect(
      find.text("'${'가' * 20}…'와\n일치하는 검색 결과를 찾지 못했습니다."),
      findsOneWidget,
    );
    expect(find.text('가' * 50), findsOneWidget);
  });

  testWidgets('지우기 버튼을 누르면 초기 상태로 돌아간다', (WidgetTester tester) async {
    setUpWith(<String, String>{'005930': '삼성전자'});
    await pumpScreen(tester);
    await search(tester, '삼성');
    expect(find.text('005930 · 코스피'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsNothing);
  });

  group('관심 등록', () {
    testWidgets('별을 누르면 채워지고 등록 토스트가 뜬다', (WidgetTester tester) async {
      setUpWith(<String, String>{'005930': '삼성전자'});
      await pumpScreen(tester);
      await search(tester, '삼성');

      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pump();

      expect(favorites.isFavorite('005930'), isTrue);
      expect(find.text('관심이 등록되었습니다'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('다시 누르면 해제되고 해제 토스트가 뜬다', (WidgetTester tester) async {
      setUpWith(<String, String>{'005930': '삼성전자'});
      await pumpScreen(tester);
      await search(tester, '삼성');

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.byIcon(Icons.star_rounded).first);
      await tester.pump();

      expect(favorites.isFavorite('005930'), isFalse);
      expect(find.text('관심이 해제되었습니다'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('토스트는 잠시 뒤 사라진다', (WidgetTester tester) async {
      setUpWith(<String, String>{'005930': '삼성전자'});
      await pumpScreen(tester);
      await search(tester, '삼성');

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pump();
      expect(find.text('관심이 등록되었습니다'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('관심이 등록되었습니다'), findsNothing);
    });
  });

  testWidgets('이미 등록한 종목은 검색 직후부터 채운 별로 보인다', (WidgetTester tester) async {
    setUpWith(<String, String>{'005930': '삼성전자'});
    favorites.toggle(symbol: '005930', name: '삼성전자', marketName: '코스피');

    await pumpScreen(tester);
    await search(tester, '삼성');

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
  });
}
