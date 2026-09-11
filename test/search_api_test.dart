import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/search_api.dart';
import 'package:edencrew_assignment_starter/models/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 필터 조건을 확인할 최소 입력. 실제 응답에서 확인한 모양을 그대로 옮겼다.
String bodyWith(List<Map<String, dynamic>> items) =>
    jsonEncode(<String, dynamic>{'query': 'x', 'items': items});

const Map<String, dynamic> domesticStock = <String, dynamic>{
  'code': '005930',
  'name': '삼성전자',
  'typeName': '코스피',
  'nationCode': 'KOR',
  'category': 'stock',
};

void main() {
  test('저장해 둔 실제 응답에서 국내 종목을 읽어낸다', () {
    final String body = File(
      'assets/mock/search_autocomplete.json',
    ).readAsStringSync();

    final List<SearchResult> results = parseSearchResults(body);

    expect(results, isNotEmpty);
    expect(results.first.symbol, '005930');
    expect(results.first.name, '삼성전자');
    expect(results.first.marketName, '코스피');
    expect(results.first.canonicalId, 'domestic:005930');
  });

  group('국내 주식만 통과시킨다', () {
    test('해외 주식은 제외한다', () {
      final String body = bodyWith(<Map<String, dynamic>>[
        domesticStock,
        <String, dynamic>{
          'code': 'AAPL',
          'name': '애플',
          'typeName': '나스닥 증권거래소',
          'nationCode': 'USA',
          'category': 'stock',
        },
      ]);

      expect(
        parseSearchResults(body).map((SearchResult r) => r.symbol),
        <String>['005930'],
      );
    });

    test('지수는 제외한다', () {
      // 지수는 nationCode가 null로 온다.
      final String body = bodyWith(<Map<String, dynamic>>[
        domesticStock,
        <String, dynamic>{
          'code': 'KOSPI',
          'name': '코스피',
          'typeName': '국내지수',
          'nationCode': null,
          'category': 'index',
        },
      ]);

      expect(
        parseSearchResults(body).map((SearchResult r) => r.symbol),
        <String>['005930'],
      );
    });

    test('6자리가 아닌 종목코드는 제외한다', () {
      final String body = bodyWith(<Map<String, dynamic>>[
        domesticStock,
        <String, dynamic>{
          'code': '2788',
          'name': '애플인터내셔널',
          'typeName': '도쿄 거래소',
          'nationCode': 'KOR',
          'category': 'stock',
        },
      ]);

      expect(
        parseSearchResults(body).map((SearchResult r) => r.symbol),
        <String>['005930'],
      );
    });

    test('코스닥 종목도 통과시킨다', () {
      final String body = bodyWith(<Map<String, dynamic>>[
        <String, dynamic>{
          'code': '247540',
          'name': '에코프로비엠',
          'typeName': '코스닥',
          'nationCode': 'KOR',
          'category': 'stock',
        },
      ]);

      expect(parseSearchResults(body).single.marketName, '코스닥');
    });
  });

  test('items가 없으면 빈 목록을 돌려준다', () {
    expect(parseSearchResults('{"query":"x"}'), isEmpty);
  });

  group('SearchApi', () {
    test('검색어가 비어 있으면 요청하지 않는다', () async {
      bool requested = false;
      final SearchApi api = SearchApi(
        NaverClient(
          httpClient: MockClient((http.Request request) async {
            requested = true;
            return http.Response('{}', 200);
          }),
        ),
      );

      expect(await api.search('   '), isEmpty);
      expect(requested, isFalse);
    });

    test('검색어를 q 파라미터로 넘긴다', () async {
      late Uri captured;
      final SearchApi api = SearchApi(
        NaverClient(
          httpClient: MockClient((http.Request request) async {
            captured = request.url;
            // content-type을 안 붙이면 http 패키지가 본문을 latin1로 인코딩해
            // 한글을 담지 못한다. 실제 응답과 같은 헤더를 붙인다.
            return http.Response(
              bodyWith(<Map<String, dynamic>>[domesticStock]),
              200,
              headers: <String, String>{
                'content-type': 'application/json;charset=UTF-8',
              },
            );
          }),
        ),
      );

      final List<SearchResult> results = await api.search('삼성');

      expect(captured.host, 'ac.stock.naver.com');
      expect(captured.queryParameters['q'], '삼성');
      expect(results.single.symbol, '005930');
    });
  });
}
