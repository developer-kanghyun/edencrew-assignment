import 'package:edencrew_assignment_starter/data/naver_client.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 네트워크를 타지 않는 저장소. 시세 요청에는 빈 응답을 준다.
///
/// 관심 상태나 화면 동작만 확인하는 테스트에서 쓴다. 실제 응답 파싱은
/// 각 API의 테스트가 목업 파일로 따로 검증한다.
StockRepository fakeRepository({
  Future<http.Response> Function(http.Request request)? onRequest,
}) {
  return StockRepository(
    client: NaverClient(
      httpClient: MockClient(
        onRequest ??
            (http.Request request) async => http.Response(
              '{"resultCode":"success","result":{"areas":[]}}',
              200,
              headers: <String, String>{
                'content-type': 'application/json;charset=utf-8',
              },
            ),
      ),
    ),
  );
}
