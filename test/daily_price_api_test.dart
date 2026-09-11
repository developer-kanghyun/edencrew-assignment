import 'dart:io';

import 'package:edencrew_assignment_starter/data/daily_price_api.dart';
import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  List<int> mockBytes(String fileName) =>
      File('assets/mock/$fileName').readAsBytesSync();

  String mockHtml(String fileName) =>
      NaverClient.decodeBody(mockBytes(fileName), 'text/html;charset=EUC-KR');

  group('표 파싱', () {
    test('한 페이지에서 10거래일을 읽는다', () {
      final DailyPricePage page = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      );

      expect(page.prices, hasLength(10));
    });

    test('날짜를 yyyyMMdd로 정규화한다', () {
      final DailyPrice first = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      ).prices.first;

      expect(first.date, matches(RegExp(r'^\d{8}$')));
      expect(first.monthDay, matches(RegExp(r'^\d{2}\.\d{2}$')));
    });

    test('쉼표가 붙은 숫자를 정수로 바꾼다', () {
      final DailyPrice first = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      ).prices.first;

      expect(first.closePrice, greaterThan(0));
      expect(first.openPrice, greaterThan(0));
      expect(first.accumulatedTradingVolume, greaterThan(1000));
      expect(first.highPrice, greaterThanOrEqualTo(first.lowPrice));
    });

    test('열 순서를 지켜 읽는다', () {
      // 표는 날짜, 종가, 전일비, 시가, 고가, 저가, 거래량 순이다.
      // 전일비를 시가로 잘못 읽으면 고가와 저가 사이를 벗어난다.
      for (final DailyPrice price
          in parseDailyPricePage(mockHtml('daily_price_page1.html')).prices) {
        expect(price.openPrice, lessThanOrEqualTo(price.highPrice));
        expect(price.openPrice, greaterThanOrEqualTo(price.lowPrice));
        expect(price.closePrice, lessThanOrEqualTo(price.highPrice));
        expect(price.closePrice, greaterThanOrEqualTo(price.lowPrice));
      }
    });

    test('최신 거래일이 앞에 온다', () {
      final List<DailyPrice> prices = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      ).prices;

      for (int i = 0; i < prices.length - 1; i++) {
        expect(
          prices[i].date.compareTo(prices[i + 1].date),
          greaterThan(0),
          reason: '${prices[i].date}가 ${prices[i + 1].date}보다 뒤에 있음',
        );
      }
    });

    test('2페이지는 1페이지보다 과거다', () {
      final List<DailyPrice> page1 = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      ).prices;
      final List<DailyPrice> page2 = parseDailyPricePage(
        mockHtml('daily_price_page2.html'),
      ).prices;

      expect(page1.last.date.compareTo(page2.first.date), greaterThan(0));
    });
  });

  group('마지막 페이지', () {
    test('맨뒤 링크에서 마지막 페이지 번호를 읽는다', () {
      final DailyPricePage page = parseDailyPricePage(
        mockHtml('daily_price_page1.html'),
      );

      expect(page.lastPage, greaterThan(1));
    });

    test('맨뒤 링크가 없으면 보이는 페이지 중 가장 큰 값을 쓴다', () {
      const String html = '''
        <table class="type2">
          <tr><td align="center">2026.09.11</td><td>100</td><td>1</td>
              <td>100</td><td>110</td><td>90</td><td>1,000</td></tr>
        </table>
        <table class="Nnavi">
          <tr>
            <td><a href="/item/sise_day.naver?code=005930&page=1">1</a></td>
            <td><a href="/item/sise_day.naver?code=005930&page=3">3</a></td>
          </tr>
        </table>
      ''';

      expect(parseDailyPricePage(html, currentPage: 3).lastPage, 3);
    });

    test('페이지 링크가 아예 없으면 현재 페이지를 마지막으로 본다', () {
      expect(parseDailyPricePage('<html></html>', currentPage: 7).lastPage, 7);
    });
  });

  group('DailyPriceApi', () {
    test('종목코드와 페이지를 파라미터로 넘긴다', () async {
      late Uri captured;
      final DailyPriceApi api = DailyPriceApi(
        NaverClient(
          httpClient: MockClient((http.Request request) async {
            captured = request.url;
            return http.Response.bytes(
              mockBytes('daily_price_page1.html'),
              200,
              headers: <String, String>{
                'content-type': 'text/html;charset=EUC-KR',
              },
            );
          }),
        ),
      );

      final DailyPricePage page = await api.fetchPage('005930', 2);

      expect(captured.queryParameters['code'], '005930');
      expect(captured.queryParameters['page'], '2');
      expect(page.prices, hasLength(10));
    });
  });
}
