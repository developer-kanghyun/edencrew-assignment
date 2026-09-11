import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/screens/detail_screen.dart';
import 'package:edencrew_assignment_starter/state/app_scope.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/widgets/candle_chart.dart';
import 'package:edencrew_assignment_starter/widgets/quote_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late StockRepository repository;
  late FavoritesState favorites;
  late List<int> requestedPages;

  setUp(() {
    requestedPages = <int>[];
    repository = StockRepository(
      client: NaverClient(httpClient: _clientReturning(requestedPages)),
    );
    favorites = FavoritesState(repository);
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        favorites: favorites,
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const DetailScreen(
            symbol: '005930',
            name: '삼성전자',
            marketName: '코스피',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('헤더에 종목명과 코드·시장을 보여준다', (WidgetTester tester) async {
    await pumpDetail(tester);

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsOneWidget);
  });

  testWidgets('현재가와 등락을 화살표와 함께 보여준다', (WidgetTester tester) async {
    await pumpDetail(tester);

    expect(find.text('259,500'), findsOneWidget);
    expect(find.textContaining('▼'), findsOneWidget);
  });

  testWidgets('요약 카드 다섯 칸을 보여준다', (WidgetTester tester) async {
    await pumpDetail(tester);

    for (final String label in <String>['시가', '고가', '저가', '거래량', '시가총액']) {
      expect(
        find.descendant(
          of: find.byType(QuoteSummaryCard),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('거래량과 시가총액은 축약해서 보여준다', (WidgetTester tester) async {
    await pumpDetail(tester);

    expect(find.textContaining('천'), findsWidgets);
    expect(find.textContaining('조'), findsWidgets);
  });

  testWidgets('기간 탭 네 개가 모두 있고 기본은 1개월이다', (WidgetTester tester) async {
    await pumpDetail(tester);

    for (final String label in <String>['1개월', '3개월', '6개월', '1년']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('캔들 차트를 그린다', (WidgetTester tester) async {
    await pumpDetail(tester);

    expect(find.byType(CandleChart), findsOneWidget);
  });

  testWidgets('일별 시세 표의 컬럼이 있다', (WidgetTester tester) async {
    await pumpDetail(tester);

    expect(find.text('일별 시세'), findsOneWidget);
    expect(find.text('날짜'), findsOneWidget);
    expect(find.text('종가'), findsOneWidget);
    expect(find.text('등락'), findsOneWidget);
    expect(find.text('거래량'), findsWidgets); // 요약 카드에도 있다
  });

  testWidgets('기간을 넓히면 이미 받은 페이지는 다시 요청하지 않는다', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester);
    expect(requestedPages..sort(), <int>[1, 2]); // 1개월 = 2페이지

    requestedPages.clear();
    await tester.tap(find.text('3개월'));
    await tester.pumpAndSettle();

    // 3개월 = 6페이지인데 1, 2는 캐시에 있으므로 3~6만 나간다.
    expect(requestedPages..sort(), <int>[3, 4, 5, 6]);
  });

  testWidgets('별을 누르면 관심 상태가 바뀐다', (WidgetTester tester) async {
    await pumpDetail(tester);
    expect(favorites.isFavorite('005930'), isFalse);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();

    expect(favorites.isFavorite('005930'), isTrue);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}

/// 시세는 목업 파일로, 일별 시세는 페이지 번호를 심은 가짜 HTML로 답한다.
MockClient _clientReturning(List<int> requestedPages) {
  return MockClient((http.Request request) async {
    if (request.url.host.contains('polling')) {
      return http.Response.bytes(
        File('assets/mock/realtime_quote.json').readAsBytesSync(),
        200,
        headers: <String, String>{'content-type': 'text/plain;charset=EUC-KR'},
      );
    }

    final int page = int.parse(request.url.queryParameters['page'] ?? '1');
    requestedPages.add(page);
    return http.Response.bytes(
      utf8.encode(_fakeDailyPage(page)),
      200,
      headers: <String, String>{'content-type': 'text/html;charset=utf-8'},
    );
  });
}

String _fakeDailyPage(int page) {
  final StringBuffer html = StringBuffer('<table class="type2">');
  for (int i = 1; i <= 10; i++) {
    final String date =
        '20${page.toString().padLeft(2, '0')}.01.${i.toString().padLeft(2, '0')}';
    html.write(
      '<tr><td align="center">$date</td><td>1,000</td><td>10</td>'
      '<td>1,000</td><td>1,100</td><td>900</td><td>12,345</td></tr>',
    );
  }
  html.write(
    '</table><table class="Nnavi"><tr><td class="pgRR">'
    '<a href="/item/sise_day.naver?code=005930&page=756">맨뒤</a>'
    '</td></tr></table>',
  );
  return html.toString();
}
