import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:http/http.dart' as http;

/// 네이버 응답을 가져오지 못했을 때 던진다. 화면에서 에러 상태를 그리는 근거가 된다.
class NaverApiException implements Exception {
  NaverApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NaverApiException($statusCode): $message';
}

/// 네이버 endpoint 4개가 공통으로 쓰는 HTTP 호출부.
///
/// 응답 본문을 문자열로 만드는 책임까지 여기서 진다. 각 API는 이미 디코딩된
/// 문자열만 받아 파싱에 집중한다.
class NaverClient {
  NaverClient({http.Client? httpClient, this.timeout = const Duration(seconds: 10)})
    : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;

  /// 네이버는 브라우저가 아닌 요청을 막는 경우가 있어 최소한의 헤더를 붙인다.
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    'Referer': 'https://finance.naver.com/',
  };

  Future<String> getAsString(Uri url) async {
    final http.Response response;
    try {
      response = await _http.get(url, headers: _headers).timeout(timeout);
    } on Exception catch (error) {
      throw NaverApiException('요청에 실패했습니다: $error');
    }

    if (response.statusCode != 200) {
      throw NaverApiException(
        '응답이 정상이 아닙니다',
        statusCode: response.statusCode,
      );
    }

    return decodeBody(response.bodyBytes, response.headers['content-type']);
  }

  /// 응답 바이트를 헤더가 알려준 charset으로 디코딩한다.
  ///
  /// `http` 패키지의 `response.body`를 쓰지 않는 이유는, 모르는 charset을 만나면
  /// 예외 없이 latin1로 디코딩해서 한글만 조용히 깨지기 때문이다.
  /// endpoint마다 인코딩을 하드코딩하지 않고 헤더를 따르므로, 네이버가 인코딩을
  /// 바꿔도 코드를 고칠 필요가 없다.
  static String decodeBody(List<int> bytes, String? contentType) {
    return switch (_charsetOf(contentType)) {
      'euc-kr' || 'ks_c_5601-1987' || 'cp949' || 'windows-949' =>
        cp949.decode(bytes),
      _ => utf8.decode(bytes),
    };
  }

  static String? _charsetOf(String? contentType) {
    if (contentType == null) return null;
    final RegExpMatch? match = RegExp(
      r'charset\s*=\s*"?([\w-]+)"?',
      caseSensitive: false,
    ).firstMatch(contentType);
    return match?.group(1)?.toLowerCase();
  }

  void close() => _http.close();
}
