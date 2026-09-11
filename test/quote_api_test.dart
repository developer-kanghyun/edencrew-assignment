import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/quote_api.dart';
import 'package:edencrew_assignment_starter/models/quote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  List<int> mockBytes(String fileName) =>
      File('assets/mock/$fileName').readAsBytesSync();

  String mockBody(String fileName) => NaverClient.decodeBody(
    mockBytes(fileName),
    'text/plain;charset=EUC-KR',
  );

  group('parseQuotes', () {
    test('요청한 두 종목이 모두 종목코드로 찾아진다', () {
      final Map<String, Quote> quotes = parseQuotes(
        mockBody('realtime_quote.json'),
      );

      expect(quotes.keys, containsAll(<String>['005930', '000660']));
    });

    test('시세 값이 모델에 옮겨진다', () {
      final Quote quote = parseQuotes(mockBody('realtime_quote.json'))['005930']!;

      expect(quote.symbol, '005930');
      expect(quote.currentPrice, greaterThan(0));
      expect(quote.previousClose, greaterThan(0));
      expect(quote.open, greaterThan(0));
      expect(quote.high, greaterThanOrEqualTo(quote.low));
      expect(quote.accumulatedVolume, greaterThan(0));
      expect(quote.listedShares, greaterThan(0));
    });

    test('등락은 응답 필드가 아니라 현재가와 전일종가로 계산한다', () {
      final Quote quote = parseQuotes(mockBody('realtime_quote.json'))['005930']!;

      expect(quote.change, quote.currentPrice - quote.previousClose);
      expect(
        quote.direction,
        quote.change > 0
            ? PriceDirection.up
            : quote.change < 0
            ? PriceDirection.down
            : PriceDirection.flat,
      );
    });

    test('응답이 비어 있으면 빈 Map을 돌려준다', () {
      expect(parseQuotes('{"resultCode":"success"}'), isEmpty);
    });
  });

  group('QuoteApi', () {
    test('종목이 없으면 요청하지 않는다', () async {
      bool requested = false;
      final QuoteApi api = QuoteApi(
        NaverClient(
          httpClient: MockClient((http.Request request) async {
            requested = true;
            return http.Response('{}', 200);
          }),
        ),
      );

      expect(await api.fetchQuotes(<String>[]), isEmpty);
      expect(requested, isFalse);
    });

    test('여러 종목을 한 번의 요청으로 조회한다', () async {
      int requestCount = 0;
      late Uri captured;

      final QuoteApi api = QuoteApi(
        NaverClient(
          httpClient: MockClient((http.Request request) async {
            requestCount++;
            captured = request.url;
            return http.Response.bytes(
              mockBytes('realtime_quote.json'),
              200,
              headers: <String, String>{
                'content-type': 'text/plain;charset=EUC-KR',
              },
            );
          }),
        ),
      );

      final Map<String, Quote> quotes = await api.fetchQuotes(<String>[
        '005930',
        '000660',
      ]);

      expect(requestCount, 1);
      expect(
        captured.queryParameters['query'],
        'SERVICE_ITEM:005930,000660',
      );
      expect(quotes.length, 2);
    });
  });
}
