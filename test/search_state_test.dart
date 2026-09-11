import 'package:edencrew_assignment_starter/state/search_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

/// 디바운스가 실제로 지나가도록 기다린다.
Future<void> afterDebounce() =>
    Future<void>.delayed(SearchState.debounce + const Duration(milliseconds: 120));

void main() {
  test('검색어를 입력하기 전에는 초기 상태다', () {
    final SearchState state = SearchState(fakeRepository());

    expect(state.isBeforeSearch, isTrue);
    expect(state.results, isEmpty);
    expect(state.hasNoResult, isFalse);
  });

  test('입력하면 결과를 가져온다', () async {
    final SearchState state = SearchState(
      fakeRepository(
        onRequest: (http.Request request) async =>
            autocompleteResponse(<String, String>{'005930': '삼성전자'}),
      ),
    );

    state.onQueryChanged('삼성');
    await afterDebounce();

    expect(state.results, hasLength(1));
    expect(state.results.single.name, '삼성전자');
    expect(state.isLoading, isFalse);
  });

  test('결과가 없으면 hasNoResult가 true다', () async {
    final SearchState state = SearchState(
      fakeRepository(
        onRequest: (http.Request request) async =>
            autocompleteResponse(<String, String>{}),
      ),
    );

    state.onQueryChanged('ㄱㄴㄷ');
    await afterDebounce();

    expect(state.hasNoResult, isTrue);
    expect(state.isBeforeSearch, isFalse);
  });

  test('입력을 지우면 초기 상태로 돌아간다', () async {
    final SearchState state = SearchState(
      fakeRepository(
        onRequest: (http.Request request) async =>
            autocompleteResponse(<String, String>{'005930': '삼성전자'}),
      ),
    );

    state.onQueryChanged('삼성');
    await afterDebounce();
    expect(state.results, isNotEmpty);

    state.clear();

    expect(state.isBeforeSearch, isTrue);
    expect(state.results, isEmpty);
    expect(state.hasNoResult, isFalse);
  });

  group('디바운스', () {
    test('빠르게 이어 치면 마지막 한 번만 요청한다', () async {
      int requestCount = 0;
      final SearchState state = SearchState(
        fakeRepository(
          onRequest: (http.Request request) async {
            requestCount++;
            return autocompleteResponse(<String, String>{'005930': '삼성전자'});
          },
        ),
      );

      state.onQueryChanged('삼');
      state.onQueryChanged('삼성');
      state.onQueryChanged('삼성전');
      state.onQueryChanged('삼성전자');
      await afterDebounce();

      expect(requestCount, 1);
    });

    test('입력 직후에는 로딩 상태다', () {
      final SearchState state = SearchState(fakeRepository());

      state.onQueryChanged('삼성');

      expect(state.isLoading, isTrue);
      // 로딩 중에는 '결과 없음'으로 보이면 안 된다.
      expect(state.hasNoResult, isFalse);
    });
  });

  test('늦게 도착한 이전 응답이 최신 결과를 덮어쓰지 않는다', () async {
    // 첫 요청은 느리게, 두 번째는 빠르게 응답하도록 만든다.
    int call = 0;
    final SearchState state = SearchState(
      fakeRepository(
        onRequest: (http.Request request) async {
          call++;
          if (call == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return autocompleteResponse(<String, String>{'000660': '오래된결과'});
          }
          return autocompleteResponse(<String, String>{'005930': '최신결과'});
        },
      ),
    );

    state.onQueryChanged('첫번째');
    await afterDebounce();
    state.onQueryChanged('두번째');
    await afterDebounce();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(state.results.single.name, '최신결과');
  });
}
