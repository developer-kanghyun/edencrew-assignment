import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:edencrew_assignment_starter/state/detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrice priceOf(String date, int close) => DailyPrice(
  date: date,
  closePrice: close,
  openPrice: close,
  highPrice: close,
  lowPrice: close,
  accumulatedTradingVolume: 0,
);

void main() {
  group('toDailyRows', () {
    test('등락은 바로 앞 거래일의 종가 차이다', () {
      // 목록은 최신순이므로 다음 원소가 전 거래일이다.
      final List<DailyPriceRow> rows = toDailyRows(<DailyPrice>[
        priceOf('20260327', 179700),
        priceOf('20260326', 180100),
        priceOf('20260325', 178900),
      ]);

      expect(rows[0].change, 179700 - 180100); // -400
      expect(rows[1].change, 180100 - 178900); // +1,200
    });

    test('가장 오래된 줄은 비교 대상이 없어 null이다', () {
      final List<DailyPriceRow> rows = toDailyRows(<DailyPrice>[
        priceOf('20260327', 179700),
        priceOf('20260326', 180100),
      ]);

      expect(rows.last.change, isNull);
    });

    test('한 건뿐이면 등락이 없다', () {
      final List<DailyPriceRow> rows = toDailyRows(<DailyPrice>[
        priceOf('20260327', 179700),
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.change, isNull);
    });

    test('빈 목록은 빈 결과다', () {
      expect(toDailyRows(const <DailyPrice>[]), isEmpty);
    });

    test('날짜 순서와 개수를 그대로 유지한다', () {
      final List<DailyPriceRow> rows = toDailyRows(<DailyPrice>[
        priceOf('20260327', 1),
        priceOf('20260326', 2),
        priceOf('20260325', 3),
      ]);

      expect(
        rows.map((DailyPriceRow r) => r.price.date),
        <String>['20260327', '20260326', '20260325'],
      );
    });
  });
}
