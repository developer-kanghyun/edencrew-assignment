import 'package:edencrew_assignment_starter/models/favorite_stock.dart';
import 'package:edencrew_assignment_starter/models/quote.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:flutter_test/flutter_test.dart';

Quote quoteOf(
  String symbol, {
  required int currentPrice,
  required int previousClose,
}) => Quote(
  symbol: symbol,
  currentPrice: currentPrice,
  previousClose: previousClose,
  open: 0,
  high: 0,
  low: 0,
  accumulatedVolume: 0,
  listedShares: 0,
);

void main() {
  late FavoritesState state;

  setUp(() {
    state = FavoritesState();
  });

  void add(String symbol, String name) {
    state.toggle(symbol: symbol, name: name, marketName: '코스피');
  }

  group('관심 등록과 해제', () {
    test('toggle을 한 번 부르면 등록되고 다시 부르면 해제된다', () {
      add('005930', '삼성전자');
      expect(state.isFavorite('005930'), isTrue);
      expect(state.stocks, hasLength(1));

      add('005930', '삼성전자');
      expect(state.isFavorite('005930'), isFalse);
      expect(state.stocks, isEmpty);
    });

    test('등록하지 않은 종목은 isFavorite이 false다', () {
      add('005930', '삼성전자');
      expect(state.isFavorite('000660'), isFalse);
    });

    test('관심 상태가 바뀌면 리스너에게 알린다', () {
      int notified = 0;
      state.addListener(() => notified++);

      add('005930', '삼성전자');
      add('005930', '삼성전자');

      expect(notified, 2);
    });
  });

  group('정렬', () {
    setUp(() {
      add('000660', 'SK하이닉스');
      add('005930', '삼성전자');
      add('035720', '카카오');
      state.applyQuotes(<String, Quote>{
        '000660': quoteOf('000660', currentPrice: 180000, previousClose: 170000),
        '005930': quoteOf('005930', currentPrice: 257750, previousClose: 269000),
        '035720': quoteOf('035720', currentPrice: 40000, previousClose: 40000),
      });
    });

    test('가나다순은 종목명 오름차순으로 정렬한다', () {
      state.setSortOrder(SortOrder.name);
      expect(
        state.stocks.map((FavoriteStock s) => s.name),
        <String>['SK하이닉스', '삼성전자', '카카오'],
      );
    });

    test('현재가순은 현재가 내림차순으로 정렬한다', () {
      state.setSortOrder(SortOrder.price);
      expect(
        state.stocks.map((FavoriteStock s) => s.symbol),
        <String>['005930', '000660', '035720'],
      );
    });

    test('등락률순은 등락률 내림차순으로 정렬한다', () {
      state.setSortOrder(SortOrder.changeRate);
      // 하이닉스 +5.88% > 카카오 0% > 삼성전자 -4.18%
      expect(
        state.stocks.map((FavoriteStock s) => s.symbol),
        <String>['000660', '035720', '005930'],
      );
    });
  });

  group('시세를 받지 못한 행', () {
    setUp(() {
      add('005930', '삼성전자');
      add('999999', '시세없는종목');
      state.applyQuotes(<String, Quote>{
        '005930': quoteOf('005930', currentPrice: 257750, previousClose: 269000),
      });
    });

    test('현재가순에서 맨 뒤로 간다', () {
      state.setSortOrder(SortOrder.price);
      expect(state.stocks.last.symbol, '999999');
    });

    test('등락률순에서도 맨 뒤로 간다', () {
      state.setSortOrder(SortOrder.changeRate);
      expect(state.stocks.last.symbol, '999999');
    });

    test('가나다순에서는 이름이 있으므로 정상 정렬된다', () {
      state.setSortOrder(SortOrder.name);
      expect(
        state.stocks.map((FavoriteStock s) => s.name),
        <String>['삼성전자', '시세없는종목'],
      );
    });
  });

  group('applyQuotes', () {
    test('응답에 없는 종목의 기존 시세는 유지한다', () {
      add('005930', '삼성전자');
      add('000660', 'SK하이닉스');
      state.applyQuotes(<String, Quote>{
        '005930': quoteOf('005930', currentPrice: 100, previousClose: 100),
        '000660': quoteOf('000660', currentPrice: 200, previousClose: 200),
      });

      state.applyQuotes(<String, Quote>{
        '005930': quoteOf('005930', currentPrice: 150, previousClose: 100),
      });

      final Map<String, FavoriteStock> bySymbol = <String, FavoriteStock>{
        for (final FavoriteStock s in state.stocks) s.symbol: s,
      };
      expect(bySymbol['005930']!.quote!.currentPrice, 150);
      expect(bySymbol['000660']!.quote!.currentPrice, 200);
    });
  });

  group('정렬 기준 변경', () {
    test('같은 기준으로 다시 설정하면 알리지 않는다', () {
      state.setSortOrder(SortOrder.name);

      int notified = 0;
      state.addListener(() => notified++);
      state.setSortOrder(SortOrder.name);

      expect(notified, 0);
    });
  });
}
