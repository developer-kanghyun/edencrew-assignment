import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/stock_meta_api.dart';
import 'package:edencrew_assignment_starter/models/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('저장해 둔 응답에서 종목명과 거래소명을 읽는다', () {
    final SearchResult meta = parseStockMeta(
      File('assets/mock/stock_meta.json').readAsStringSync(),
    );

    expect(meta.symbol, '005930');
    expect(meta.name, '삼성전자');
    expect(meta.marketName, '코스피');
  });

  test('종목코드를 경로에 넣어 요청한다', () async {
    late Uri captured;
    final StockMetaApi api = StockMetaApi(
      NaverClient(
        httpClient: MockClient((http.Request request) async {
          captured = request.url;
          return http.Response.bytes(
            File('assets/mock/stock_meta.json').readAsBytesSync(),
            200,
            headers: <String, String>{
              'content-type': 'application/json;charset=utf-8',
            },
          );
        }),
      ),
    );

    await api.fetchMeta('005930');

    expect(captured.host, 'stock.naver.com');
    expect(captured.path, endsWith('/domestic/stock/005930'));
  });
}
