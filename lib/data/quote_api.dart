import 'dart:convert';

import '../models/quote.dart';
import 'dto/quote_dto.dart';
import 'naver_client.dart';

/// 실시간 시세 endpoint.
class QuoteApi {
  const QuoteApi(this._client);

  final NaverClient _client;

  /// 여러 종목의 시세를 **한 번의 요청으로** 가져온다.
  ///
  /// query 파라미터에 종목코드를 쉼표로 이어 붙이면 응답이 한 번에 온다.
  /// 관심종목이 20개여도 요청은 한 번이다.
  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};

    final Uri url = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );

    return parseQuotes(await _client.getAsString(url));
  }
}

/// 응답 본문을 종목코드로 찾을 수 있는 형태로 바꾼다.
///
/// 목록 화면이 행마다 자기 시세를 꺼내야 해서, 리스트가 아니라 Map으로 돌려준다.
Map<String, Quote> parseQuotes(String body) {
  final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
  final Map<String, dynamic>? result = json['result'] as Map<String, dynamic>?;
  final List<dynamic> areas = result?['areas'] as List<dynamic>? ?? <dynamic>[];

  final Map<String, Quote> quotes = <String, Quote>{};
  for (final dynamic area in areas) {
    final List<dynamic> datas =
        (area as Map<String, dynamic>)['datas'] as List<dynamic>? ?? <dynamic>[];

    for (final dynamic data in datas) {
      final QuoteDto dto = QuoteDto.fromJson(data as Map<String, dynamic>);
      if (dto.cd.isEmpty) continue;
      quotes[dto.cd] = dto.toModel();
    }
  }
  return quotes;
}
