import 'dart:convert';
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// 네이버 endpoint 중 실시간 시세와 일별 시세는 EUC-KR로 응답한다.
/// Dart 기본 라이브러리에는 EUC-KR 변환표가 없어 외부 패키지가 필요하다.
///
/// CP949는 EUC-KR을 그대로 포함하는 확장 규격이라 EUC-KR 응답을 CP949로 읽어도
/// 결과가 같다. 처음 시도한 charset 패키지는 같은 바이트를 한자로 바꿔놓으면서도
/// 예외를 던지지 않아, 실제 한글이 나오는지를 여기서 검증한다.
void main() {
  List<int> mockBytes(String fileName) =>
      File('assets/mock/$fileName').readAsBytesSync();

  test('실시간 시세 응답이 읽을 수 있는 한글로 디코딩된다', () {
    final String decoded = cp949.decode(mockBytes('realtime_quote.json'));

    expect(decoded, contains('삼성전자'));
    expect(decoded, contains('SK하이닉스'));
  });

  test('일별 시세 HTML이 읽을 수 있는 한글로 디코딩된다', () {
    final String decoded = cp949.decode(mockBytes('daily_price_page1.html'));

    expect(decoded, contains('날짜'));
    expect(decoded, contains('거래량'));
    expect(decoded, contains('전일비'));
  });

  test('디코딩한 문자열이 그대로 JSON으로 파싱된다', () {
    final String decoded = cp949.decode(mockBytes('realtime_quote.json'));
    final Map<String, dynamic> json =
        jsonDecode(decoded) as Map<String, dynamic>;

    expect(json['resultCode'], 'success');
  });

  test('같은 바이트를 latin1로 읽으면 예외 없이 한글만 깨진다', () {
    // http 패키지의 response.body는 모르는 charset을 만나면 예외를 던지지 않고
    // latin1로 디코딩한다. 숫자는 멀쩡하고 JSON 파싱도 성공해서 실패를 알아채기
    // 어렵다. bodyBytes를 직접 디코딩해야 하는 이유를 여기 고정해 둔다.
    final String wrong = latin1.decode(mockBytes('realtime_quote.json'));

    expect(wrong, isNot(contains('삼성전자')));
    expect(
      (jsonDecode(wrong) as Map<String, dynamic>)['resultCode'],
      'success',
    );
  });

  test('UTF-8 응답은 그대로 읽힌다', () {
    expect(
      utf8.decode(mockBytes('search_autocomplete.json')),
      contains('삼성전자'),
    );
    expect(utf8.decode(mockBytes('stock_meta.json')), contains('코스피'));
  });
}
