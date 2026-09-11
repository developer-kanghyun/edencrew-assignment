import 'package:edencrew_assignment_starter/utils/highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// 결과를 `[겹치는 부분]나머지` 형태의 문자열로 바꿔 읽기 쉽게 비교한다.
String render(String text, String query) =>
    splitHighlight(text, query).map((HighlightSegment s) => '$s').join();

void main() {
  test('검색어와 겹치는 앞부분을 잘라낸다', () {
    expect(render('삼성전자', '삼성'), '[삼성]전자');
  });

  test('가운데에 있어도 찾는다', () {
    expect(render('에코프로비엠', '프로'), '에코[프로]비엠');
  });

  test('끝에 있어도 찾는다', () {
    expect(render('삼성전자우', '전자우'), '삼성[전자우]');
  });

  test('여러 번 나오면 모두 표시한다', () {
    expect(render('삼성전자 삼성', '삼성'), '[삼성]전자 [삼성]');
  });

  test('전체가 일치하면 통째로 표시한다', () {
    expect(render('카카오', '카카오'), '[카카오]');
  });

  test('겹치는 부분이 없으면 그대로 둔다', () {
    expect(render('삼성전자', '하이닉스'), '삼성전자');
  });

  test('검색어가 비어 있으면 그대로 둔다', () {
    expect(render('삼성전자', ''), '삼성전자');
    expect(render('삼성전자', '   '), '삼성전자');
  });

  test('영문은 대소문자를 구분하지 않는다', () {
    expect(render('KODEX 200', 'kodex'), '[KODEX] 200');
    expect(render('SK하이닉스', 'sk'), '[SK]하이닉스');
  });

  test('원본 대소문자는 보존한다', () {
    final List<HighlightSegment> segments = splitHighlight('KODEX 200', 'kodex');
    expect(segments.first.text, 'KODEX');
  });

  test('종목코드로 검색해도 동작한다', () {
    expect(render('005930', '0059'), '[0059]30');
  });
}
