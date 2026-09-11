import 'dart:convert';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/chart_period.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 페이지 번호를 날짜에 심은 가짜 응답. 어느 페이지가 섞여 들어왔는지 확인할 수 있다.
String fakePage({required int page, required int lastPage, int rows = 10}) {
  final StringBuffer html = StringBuffer('<table class="type2">');
  for (int i = 1; i <= rows; i++) {
    final String date =
        '20${page.toString().padLeft(2, '0')}.01.${i.toString().padLeft(2, '0')}';
    html.write(
      '<tr>'
      '<td align="center">$date</td>'
      '<td>1,000</td><td>10</td>'
      '<td>1,000</td><td>1,100</td><td>900</td><td>12,345</td>'
      '</tr>',
    );
  }
  html.write('</table><table class="Nnavi"><tr>');
  if (page < lastPage) {
    html.write(
      '<td class="pgRR">'
      '<a href="/item/sise_day.naver?code=005930&page=$lastPage">맨뒤</a>'
      '</td>',
    );
  }
  html.write('</tr></table>');
  return html.toString();
}

void main() {
  late List<int> requestedPages;

  StockRepository repositoryWith({required int lastPage}) {
    requestedPages = <int>[];
    return StockRepository(
      client: NaverClient(
        httpClient: MockClient((http.Request request) async {
          final int page =
              int.parse(request.url.queryParameters['page'] ?? '1');
          requestedPages.add(page);
          return http.Response.bytes(
            utf8.encode(fakePage(page: page, lastPage: lastPage)),
            200,
            headers: <String, String>{
              'content-type': 'text/html;charset=utf-8',
            },
          );
        }),
      ),
    );
  }

  group('필요한 만큼만 요청한다', () {
    test('1개월은 2페이지만 받는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

      expect(requestedPages..sort(), <int>[1, 2]);
    });

    test('1년은 25페이지를 받는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneYear);

      expect(requestedPages, hasLength(25));
      expect(requestedPages.reduce((int a, int b) => a > b ? a : b), 25);
    });

    test('마지막 페이지보다 큰 페이지는 요청하지 않는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 3);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneYear);

      expect(requestedPages..sort(), <int>[1, 2, 3]);
    });
  });

  group('받아둔 페이지를 재사용한다', () {
    test('기간을 넓혀도 이미 받은 페이지는 다시 요청하지 않는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
      requestedPages.clear();

      await repository.fetchDailyPrices('005930', ChartPeriod.oneYear);

      expect(requestedPages, isNot(contains(1)));
      expect(requestedPages, isNot(contains(2)));
      expect(requestedPages..sort(), hasLength(23));
    });

    test('같은 기간을 다시 요청하면 네트워크를 타지 않는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
      requestedPages.clear();

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

      expect(requestedPages, isEmpty);
    });

    test('기간을 좁히면 요청이 없다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.threeMonths);
      requestedPages.clear();

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

      expect(requestedPages, isEmpty);
    });

    test('종목이 다르면 캐시를 공유하지 않는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
      requestedPages.clear();

      await repository.fetchDailyPrices('000660', ChartPeriod.oneMonth);

      expect(requestedPages..sort(), <int>[1, 2]);
    });

    test('캐시를 비우면 다시 받는다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);
      repository.clearDailyPriceCache('005930');
      requestedPages.clear();

      await repository.fetchDailyPrices('005930', ChartPeriod.oneMonth);

      expect(requestedPages..sort(), <int>[1, 2]);
    });
  });

  group('결과', () {
    test('요청한 거래일 수만큼 잘라서 돌려준다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      final List<DailyPrice> prices = await repository.fetchDailyPrices(
        '005930',
        ChartPeriod.oneMonth,
      );

      expect(prices, hasLength(ChartPeriod.oneMonth.tradingDays));
    });

    test('페이지 순서대로 이어 붙인다', () async {
      final StockRepository repository = repositoryWith(lastPage: 756);

      final List<DailyPrice> prices = await repository.fetchDailyPrices(
        '005930',
        ChartPeriod.oneMonth,
      );

      // 가짜 응답이 페이지 번호를 연도에 심어두었다. 1페이지가 앞에 와야 한다.
      expect(prices.first.date.startsWith('2001'), isTrue);
      expect(prices.last.date.startsWith('2002'), isTrue);
    });

    test('거래일이 기간보다 적으면 있는 만큼만 돌려준다', () async {
      final StockRepository repository = repositoryWith(lastPage: 3);

      final List<DailyPrice> prices = await repository.fetchDailyPrices(
        '005930',
        ChartPeriod.oneYear,
      );

      expect(prices, hasLength(30));
    });
  });
}
