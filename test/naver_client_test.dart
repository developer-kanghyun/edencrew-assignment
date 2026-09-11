import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  List<int> mockBytes(String fileName) =>
      File('assets/mock/$fileName').readAsBytesSync();

  group('decodeBody', () {
    test('EUC-KR 헤더면 한글이 제대로 나온다', () {
      expect(
        NaverClient.decodeBody(
          mockBytes('realtime_quote.json'),
          'text/plain;charset=EUC-KR',
        ),
        contains('삼성전자'),
      );
    });

    test('UTF-8 헤더면 그대로 읽는다', () {
      expect(
        NaverClient.decodeBody(
          mockBytes('search_autocomplete.json'),
          'application/json;charset=UTF-8',
        ),
        contains('삼성전자'),
      );
    });

    test('charset 표기가 없으면 UTF-8로 읽는다', () {
      expect(
        NaverClient.decodeBody(
          mockBytes('stock_meta.json'),
          'application/json',
        ),
        contains('코스피'),
      );
    });

    test('charset 표기가 대소문자나 따옴표로 달라져도 인식한다', () {
      final List<int> bytes = mockBytes('daily_price_page1.html');

      expect(
        NaverClient.decodeBody(bytes, 'text/html; CHARSET="euc-kr"'),
        contains('거래량'),
      );
    });
  });

  group('getAsString', () {
    test('EUC-KR 응답을 받아 디코딩까지 마친 문자열을 돌려준다', () async {
      final NaverClient client = NaverClient(
        httpClient: MockClient((http.Request request) async {
          return http.Response.bytes(
            mockBytes('realtime_quote.json'),
            200,
            headers: <String, String>{
              'content-type': 'text/plain;charset=EUC-KR',
            },
          );
        }),
      );

      final String body = await client.getAsString(
        Uri.parse('https://example.com'),
      );

      expect(body, contains('삼성전자'));
      expect(jsonDecode(body), isA<Map<String, dynamic>>());
    });

    test('브라우저 흉내 헤더를 함께 보낸다', () async {
      late http.Request captured;
      final NaverClient client = NaverClient(
        httpClient: MockClient((http.Request request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
      );

      await client.getAsString(Uri.parse('https://example.com'));

      expect(captured.headers['User-Agent'], contains('Mozilla'));
      expect(captured.headers['Referer'], contains('naver.com'));
    });

    test('200이 아니면 NaverApiException을 던진다', () async {
      final NaverClient client = NaverClient(
        httpClient: MockClient((http.Request request) async {
          return http.Response('', 503);
        }),
      );

      expect(
        () => client.getAsString(Uri.parse('https://example.com')),
        throwsA(
          isA<NaverApiException>().having(
            (NaverApiException e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('네트워크가 끊기면 NaverApiException으로 감싼다', () async {
      final NaverClient client = NaverClient(
        httpClient: MockClient((http.Request request) async {
          throw const SocketException('연결 실패');
        }),
      );

      expect(
        () => client.getAsString(Uri.parse('https://example.com')),
        throwsA(isA<NaverApiException>()),
      );
    });
  });
}
