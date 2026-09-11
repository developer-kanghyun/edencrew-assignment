import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/daily_price.dart';
import 'dto/daily_price_dto.dart';
import 'naver_client.dart';

/// 일별 시세 한 페이지의 파싱 결과.
class DailyPricePage {
  const DailyPricePage({required this.prices, required this.lastPage});

  /// 최신 거래일이 앞에 온다. 한 페이지에 10거래일이 들어 있다.
  final List<DailyPrice> prices;

  /// 이 종목의 마지막 페이지 번호. 이보다 큰 페이지는 요청하지 않는다.
  final int lastPage;
}

/// 일별 시세 endpoint. JSON이 아니라 HTML을 돌려준다.
class DailyPriceApi {
  const DailyPriceApi(this._client);

  final NaverClient _client;

  Future<DailyPricePage> fetchPage(String symbol, int page) async {
    final Uri url = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      <String, String>{'code': symbol, 'page': '$page'},
    );

    return parseDailyPricePage(
      await _client.getAsString(url),
      currentPage: page,
    );
  }
}

/// 표의 열 순서는 `날짜, 종가, 전일비, 시가, 고가, 저가, 거래량`이다.
/// 전일비는 부호 없이 오고 방향이 CSS 클래스에 들어있어 쓰지 않는다.
/// 등락은 앞뒤 거래일의 종가 차이로 직접 계산한다.
const int _dateColumn = 0;
const int _closeColumn = 1;
const int _openColumn = 3;
const int _highColumn = 4;
const int _lowColumn = 5;
const int _volumeColumn = 6;
const int _columnCount = 7;

DailyPricePage parseDailyPricePage(String body, {int currentPage = 1}) {
  final Document document = html_parser.parse(body);

  final List<DailyPrice> prices = <DailyPrice>[];
  for (final Element row in document.querySelectorAll('tr')) {
    final List<Element> cells = row.querySelectorAll('td');
    if (cells.length != _columnCount) continue;

    final DailyPriceDto dto = DailyPriceDto(
      localDate: cells[_dateColumn].text.trim(),
      closePrice: cells[_closeColumn].text.trim(),
      openPrice: cells[_openColumn].text.trim(),
      highPrice: cells[_highColumn].text.trim(),
      lowPrice: cells[_lowColumn].text.trim(),
      accumulatedTradingVolume: cells[_volumeColumn].text.trim(),
    );
    if (!dto.isDataRow) continue;

    prices.add(dto.toModel());
  }

  return DailyPricePage(
    prices: prices,
    lastPage: _parseLastPage(document, currentPage: currentPage),
  );
}

/// `맨뒤` 링크의 page 값이 마지막 페이지다.
/// 마지막 페이지에는 그 링크가 없으므로, 보이는 페이지 번호 중 가장 큰 값을 쓴다.
int _parseLastPage(Document document, {required int currentPage}) {
  final int? fromLastLink = _pageOf(
    document.querySelector('td.pgRR a')?.attributes['href'],
  );
  if (fromLastLink != null) return fromLastLink;

  final Iterable<int> visiblePages = document
      .querySelectorAll('table.Nnavi a')
      .map((Element a) => _pageOf(a.attributes['href']))
      .whereType<int>();

  if (visiblePages.isEmpty) return currentPage;
  return visiblePages.reduce((int a, int b) => a > b ? a : b);
}

int? _pageOf(String? href) {
  if (href == null) return null;
  return int.tryParse(Uri.parse(href).queryParameters['page'] ?? '');
}
