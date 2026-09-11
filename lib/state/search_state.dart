import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/naver_client.dart';
import '../data/stock_repository.dart';
import '../models/search_result.dart';

/// 검색 화면 전용 상태. 검색어와 결과만 들고 있다.
///
/// **별표 상태는 여기에 없다.** 그건 `FavoritesState` 하나가 갖는다.
/// 화면이 별표를 따로 들고 있으면 관심 화면과 어긋나기 때문이다.
class SearchState extends ChangeNotifier {
  SearchState(this._repository);

  final StockRepository _repository;

  /// 타이핑할 때마다 요청하면 네이버가 차단할 수 있다. 입력이 멎으면 보낸다.
  static const Duration debounce = Duration(milliseconds: 300);

  String _query = '';
  List<SearchResult> _results = const <SearchResult>[];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounceTimer;

  /// 늦게 도착한 이전 요청이 최신 결과를 덮어쓰지 않도록 순번을 센다.
  int _latestRequest = 0;

  String get query => _query;
  List<SearchResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 검색어를 입력하기 전 상태인지. 화면이 초기 빈 상태를 그릴 근거가 된다.
  bool get isBeforeSearch => _query.trim().isEmpty;

  /// 검색은 했는데 결과가 없는 상태.
  bool get hasNoResult =>
      !isBeforeSearch && !_isLoading && _errorMessage == null && _results.isEmpty;

  void onQueryChanged(String value) {
    _query = value;
    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      _results = const <SearchResult>[];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _debounceTimer = Timer(debounce, () => _search(value));
  }

  void clear() => onQueryChanged('');

  Future<void> _search(String value) async {
    final int requestId = ++_latestRequest;

    try {
      final List<SearchResult> found = await _repository.search(value);
      if (requestId != _latestRequest) return; // 더 최신 입력이 있으면 버린다
      _results = found;
    } on NaverApiException catch (error) {
      if (requestId != _latestRequest) return;
      _errorMessage = error.message;
      _results = const <SearchResult>[];
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
