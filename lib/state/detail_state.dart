import 'package:flutter/foundation.dart';

import '../data/naver_client.dart';
import '../data/stock_repository.dart';
import '../models/chart_period.dart';
import '../models/daily_price.dart';
import '../models/quote.dart';

/// 종목 상세 화면 전용 상태.
///
/// **별표는 여기 없다.** 그건 `FavoritesState` 하나가 갖는다.
class DetailState extends ChangeNotifier {
  DetailState(this._repository, {required this.symbol});

  final StockRepository _repository;
  final String symbol;

  Quote? _quote;
  List<DailyPrice> _dailyPrices = const <DailyPrice>[];
  ChartPeriod _period = ChartPeriod.oneMonth;

  bool _isLoadingQuote = false;
  bool _isLoadingChart = false;
  String? _errorMessage;

  Quote? get quote => _quote;
  List<DailyPrice> get dailyPrices => _dailyPrices;
  ChartPeriod get period => _period;
  bool get isLoadingQuote => _isLoadingQuote;
  bool get isLoadingChart => _isLoadingChart;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoadingQuote = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[_loadQuote(), _loadDailyPrices()]);

    _isLoadingQuote = false;
    notifyListeners();
  }

  /// 기간 탭을 바꾼다.
  ///
  /// 저장소가 이미 받아둔 페이지는 다시 요청하지 않으므로, 1개월을 보다가
  /// 1년으로 넓히면 앞의 두 페이지는 그대로 쓰고 나머지만 받는다.
  Future<void> changePeriod(ChartPeriod next) async {
    if (_period == next) return;
    _period = next;
    notifyListeners();
    await _loadDailyPrices();
  }

  Future<void> _loadQuote() async {
    try {
      final Map<String, Quote> quotes = await _repository.fetchQuotes(
        <String>[symbol],
      );
      _quote = quotes[symbol] ?? _quote;
    } on NaverApiException catch (error) {
      _errorMessage = error.message;
    }
  }

  Future<void> _loadDailyPrices() async {
    _isLoadingChart = true;
    notifyListeners();

    try {
      _dailyPrices = await _repository.fetchDailyPrices(symbol, _period);
    } on NaverApiException catch (error) {
      _errorMessage = error.message;
    }

    _isLoadingChart = false;
    notifyListeners();
  }
}

/// 일별 시세 표에 그릴 한 줄. 등락은 응답에 없어 앞뒤 종가 차이로 만든다.
class DailyPriceRow {
  const DailyPriceRow({required this.price, required this.change});

  final DailyPrice price;

  /// 바로 앞 거래일 대비 종가 차이. **가장 오래된 줄은 비교 대상이 없어 null이다.**
  final int? change;
}

/// 일별 시세 목록을 표에 그릴 형태로 바꾼다.
///
/// 응답의 `전일비`는 부호 없이 오고 방향이 CSS 클래스에 들어 있어 쓰지 않는다.
/// 목록이 최신순이므로 바로 다음 원소가 전 거래일이다.
List<DailyPriceRow> toDailyRows(List<DailyPrice> prices) {
  return <DailyPriceRow>[
    for (int i = 0; i < prices.length; i++)
      DailyPriceRow(
        price: prices[i],
        change: i + 1 < prices.length
            ? prices[i].closePrice - prices[i + 1].closePrice
            : null,
      ),
  ];
}
