import 'package:flutter/foundation.dart';

import '../models/favorite_stock.dart';
import '../models/quote.dart';

/// 관심 화면의 정렬 기준. `label`은 헤더 칩과 정렬 바텀시트에 그대로 쓴다.
enum SortOrder {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const SortOrder(this.label);

  final String label;
}

/// 관심종목의 단일 진실 공급원(single source of truth).
///
/// 관심 · 검색 · 상세 세 화면이 모두 이 객체 하나에게 별표 상태를 묻고,
/// 이 객체 하나에게 등록 · 해제를 시킨다. 화면이 자기 별표 상태를 따로 들고 있지
/// 않으므로 세 화면이 어긋날 수 없다.
class FavoritesState extends ChangeNotifier {
  final List<FavoriteStock> _stocks = <FavoriteStock>[];
  /// 시안(`01 · 관심`)의 헤더 칩 기본값이 '가나다순'이다.
  SortOrder _sortOrder = SortOrder.name;

  SortOrder get sortOrder => _sortOrder;

  /// 현재 정렬 기준을 적용한 관심종목 목록.
  List<FavoriteStock> get stocks {
    final List<FavoriteStock> sorted = List<FavoriteStock>.of(_stocks);
    switch (_sortOrder) {
      case SortOrder.name:
        sorted.sort((FavoriteStock a, FavoriteStock b) =>
            a.name.compareTo(b.name));
      case SortOrder.price:
        sorted.sort((FavoriteStock a, FavoriteStock b) =>
            _compareDescendingNullsLast(
              a.quote?.currentPrice,
              b.quote?.currentPrice,
            ));
      case SortOrder.changeRate:
        sorted.sort((FavoriteStock a, FavoriteStock b) =>
            _compareDescendingNullsLast(
              a.quote?.changeRate,
              b.quote?.changeRate,
            ));
    }
    return sorted;
  }

  bool isFavorite(String symbol) =>
      _stocks.any((FavoriteStock stock) => stock.symbol == symbol);

  /// 별표를 켜고 끈다. 검색 화면과 상세 화면이 모두 이 메서드를 호출한다.
  ///
  /// 새로 등록할 때 이름과 시장까지 함께 받는 이유는, 관심 화면이 그 종목을
  /// 바로 그리려면 종목코드만으로는 부족하기 때문이다.
  void toggle({
    required String symbol,
    required String name,
    required String marketName,
  }) {
    if (isFavorite(symbol)) {
      _stocks.removeWhere((FavoriteStock stock) => stock.symbol == symbol);
    } else {
      _stocks.add(
        FavoriteStock(symbol: symbol, name: name, marketName: marketName),
      );
    }
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
  }

  /// 받아온 시세를 목록에 붙인다. 응답에 없는 종목은 기존 값을 그대로 둔다.
  void applyQuotes(Map<String, Quote> quotesBySymbol) {
    for (int i = 0; i < _stocks.length; i++) {
      final Quote? quote = quotesBySymbol[_stocks[i].symbol];
      if (quote != null) {
        _stocks[i] = _stocks[i].copyWith(quote: quote);
      }
    }
    notifyListeners();
  }

  /// 시세를 아직 받지 못한 행은 비교할 값이 없으므로 항상 맨 뒤로 보낸다.
  /// 0으로 취급하면 '가장 싼 종목'이나 '가장 많이 내린 종목'처럼 보여 오해를 준다.
  static int _compareDescendingNullsLast(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
