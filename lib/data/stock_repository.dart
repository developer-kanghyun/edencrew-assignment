import 'dart:math' as math;

import '../models/chart_period.dart';
import '../models/daily_price.dart';
import '../models/quote.dart';
import '../models/search_result.dart';
import 'daily_price_api.dart';
import 'naver_client.dart';
import 'quote_api.dart';
import 'search_api.dart';
import 'stock_meta_api.dart';

/// 데이터 계층의 단일 창구.
///
/// 화면은 endpoint를 직접 알지 않고 이 객체에게만 요청한다.
/// 일별 시세의 페이지 캐시도 여기서 관리한다.
class StockRepository {
  StockRepository({NaverClient? client}) : this._(client ?? NaverClient());

  StockRepository._(this._client)
    : _searchApi = SearchApi(_client),
      _quoteApi = QuoteApi(_client),
      _metaApi = StockMetaApi(_client),
      _dailyPriceApi = DailyPriceApi(_client);

  final NaverClient _client;
  final SearchApi _searchApi;
  final QuoteApi _quoteApi;
  final StockMetaApi _metaApi;
  final DailyPriceApi _dailyPriceApi;

  /// 종목코드 → (페이지 번호 → 그 페이지의 거래일들)
  final Map<String, Map<int, List<DailyPrice>>> _pageCache =
      <String, Map<int, List<DailyPrice>>>{};

  /// 종목코드 → 마지막 페이지 번호. 한 번 알아내면 다시 계산하지 않는다.
  final Map<String, int> _lastPage = <String, int>{};

  /// 공개된 endpoint라 한꺼번에 몰아치면 느려지거나 차단될 수 있어 나눠 보낸다.
  static const int _maxConcurrentRequests = 5;

  Future<List<SearchResult>> search(String query) => _searchApi.search(query);

  Future<Map<String, Quote>> fetchQuotes(List<String> symbols) =>
      _quoteApi.fetchQuotes(symbols);

  Future<SearchResult> fetchMeta(String symbol) => _metaApi.fetchMeta(symbol);

  /// 기간 탭이 요구하는 거래일만큼 일별 시세를 돌려준다.
  ///
  /// 이미 받아둔 페이지는 다시 요청하지 않는다. 1개월을 보고 1년으로 바꾸면
  /// 앞의 두 페이지는 캐시에서 꺼내고 나머지만 새로 받는다.
  Future<List<DailyPrice>> fetchDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    final Map<int, List<DailyPrice>> pages = _pageCache.putIfAbsent(
      symbol,
      () => <int, List<DailyPrice>>{},
    );

    // 마지막 페이지를 모르면 1페이지를 먼저 받아서 알아낸다.
    // 그래야 없는 페이지를 요청하는 일이 없다.
    if (!_lastPage.containsKey(symbol)) {
      await _loadPage(symbol, 1);
    }

    final int wantedPages = math.min(
      period.requiredPages,
      _lastPage[symbol] ?? 1,
    );

    final List<int> missing = <int>[
      for (int page = 1; page <= wantedPages; page++)
        if (!pages.containsKey(page)) page,
    ];
    await _loadPages(symbol, missing);

    final List<DailyPrice> merged = <DailyPrice>[
      for (int page = 1; page <= wantedPages; page++)
        ...?pages[page],
    ];

    // 마지막 페이지는 기간을 넘겨서 채워지므로 요청한 거래일 수로 자른다.
    return merged.take(period.tradingDays).toList();
  }

  Future<void> _loadPages(String symbol, List<int> pages) async {
    for (int i = 0; i < pages.length; i += _maxConcurrentRequests) {
      final List<int> chunk = pages.sublist(
        i,
        math.min(i + _maxConcurrentRequests, pages.length),
      );
      await Future.wait(chunk.map((int page) => _loadPage(symbol, page)));
    }
  }

  Future<void> _loadPage(String symbol, int page) async {
    final DailyPricePage result = await _dailyPriceApi.fetchPage(symbol, page);
    _pageCache.putIfAbsent(symbol, () => <int, List<DailyPrice>>{})[page] =
        result.prices;
    _lastPage[symbol] = result.lastPage;
  }

  /// 새로고침처럼 최신 값을 다시 받아야 할 때 쓴다.
  void clearDailyPriceCache([String? symbol]) {
    if (symbol == null) {
      _pageCache.clear();
      _lastPage.clear();
    } else {
      _pageCache.remove(symbol);
      _lastPage.remove(symbol);
    }
  }

  void dispose() => _client.close();
}
