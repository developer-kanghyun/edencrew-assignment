import 'package:edencrew_assignment_starter/models/quote.dart';
import 'package:edencrew_assignment_starter/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// intl 패키지 대신 직접 만든 표기 함수들이라 경계값을 직접 확인한다.
void main() {
  group('formatThousands', () {
    test('세 자리마다 쉼표를 넣는다', () {
      expect(formatThousands(179700), '179,700');
      expect(formatThousands(1063000000000000), '1,063,000,000,000,000');
    });

    test('쉼표가 필요 없는 자릿수는 그대로 둔다', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(7), '7');
      expect(formatThousands(999), '999');
    });

    test('자릿수가 정확히 경계일 때도 맞다', () {
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(999999), '999,999');
      expect(formatThousands(1000000), '1,000,000');
    });

    test('음수는 부호를 앞에 붙인다', () {
      expect(formatThousands(-400), '-400');
      expect(formatThousands(-1234567), '-1,234,567');
    });
  });

  group('formatChange', () {
    test('오르면 +를 붙인다', () {
      expect(formatChange(9500), '+9,500');
    });

    test('내리면 -를 붙인다', () {
      expect(formatChange(-400), '-400');
    });

    test('보합은 부호가 없다', () {
      expect(formatChange(0), '0');
    });
  });

  group('formatChangeRate', () {
    test('소수점 두 자리로 맞춘다', () {
      expect(formatChangeRate(2.36), '+2.36%');
      expect(formatChangeRate(-0.22), '-0.22%');
      expect(formatChangeRate(5), '+5.00%');
    });

    test('보합은 부호 없이 0.00%', () {
      expect(formatChangeRate(0), '0.00%');
    });

    test('셋째 자리에서 반올림한다', () {
      expect(formatChangeRate(1.235), '+1.24%');
      expect(formatChangeRate(-1.234), '-1.23%');
    });
  });

  group('formatChangeSummary', () {
    Quote quoteOf({required int currentPrice, required int previousClose}) =>
        Quote(
          symbol: '005930',
          currentPrice: currentPrice,
          previousClose: previousClose,
          open: 0,
          high: 0,
          low: 0,
          accumulatedVolume: 0,
          listedShares: 0,
        );

    test('시안의 표기 형식과 같다', () {
      expect(
        formatChangeSummary(
          quoteOf(currentPrice: 179700, previousClose: 180100),
        ),
        '-400 (-0.22%)',
      );
      expect(
        formatChangeSummary(
          quoteOf(currentPrice: 412500, previousClose: 403000),
        ),
        '+9,500 (+2.36%)',
      );
      expect(
        formatChangeSummary(
          quoteOf(currentPrice: 195400, previousClose: 195400),
        ),
        '0 (0.00%)',
      );
    });
  });

  test('formatSymbolAndMarket은 가운뎃점으로 잇는다', () {
    expect(formatSymbolAndMarket('005930', '코스피'), '005930 · 코스피');
  });
}
