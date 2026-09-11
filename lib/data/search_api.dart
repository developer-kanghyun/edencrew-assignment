import 'dart:convert';

import '../models/search_result.dart';
import 'dto/search_item_dto.dart';
import 'naver_client.dart';

/// 검색 자동완성 endpoint.
class SearchApi {
  const SearchApi(this._client);

  final NaverClient _client;

  Future<List<SearchResult>> search(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return const <SearchResult>[];

    final Uri url = Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': trimmed,
      'target': 'stock,ipo,index,marketindicator',
    });

    return parseSearchResults(await _client.getAsString(url));
  }
}

/// 응답 본문을 검색 결과 목록으로 바꾼다.
///
/// 네트워크와 분리된 순수 함수라 저장해 둔 목업만으로 검증할 수 있다.
List<SearchResult> parseSearchResults(String body) {
  final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
  final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];

  return items
      .cast<Map<String, dynamic>>()
      .map(SearchItemDto.fromJson)
      .where((SearchItemDto dto) => dto.isDomesticStock)
      .map((SearchItemDto dto) => dto.toModel())
      .toList();
}
