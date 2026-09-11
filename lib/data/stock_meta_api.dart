import 'dart:convert';

import '../models/search_result.dart';
import 'dto/stock_meta_dto.dart';
import 'naver_client.dart';

/// 종목 메타데이터 endpoint.
class StockMetaApi {
  const StockMetaApi(this._client);

  final NaverClient _client;

  Future<SearchResult> fetchMeta(String symbol) async {
    final Uri url = Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    );

    return parseStockMeta(await _client.getAsString(url));
  }
}

SearchResult parseStockMeta(String body) =>
    StockMetaDto.fromJson(jsonDecode(body) as Map<String, dynamic>).toModel();
