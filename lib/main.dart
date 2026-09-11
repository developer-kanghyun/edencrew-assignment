import 'package:flutter/material.dart';

import 'data/stock_repository.dart';
import 'screens/main_screen.dart';
import 'state/app_scope.dart';
import 'state/favorites_state.dart';
import 'theme/theme.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}

/// 앱 진입점.
///
/// [StatefulWidget]인 이유는 [FavoritesState]와 [StockRepository]를 **한 번만**
/// 만들고 종료할 때 정리하기 위해서다. `build` 안에서 만들면 화면이 다시 그려질
/// 때마다 새로 생겨 관심 목록과 캐시가 초기화된다.
class EdencrewAssignmentApp extends StatefulWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  State<EdencrewAssignmentApp> createState() => _EdencrewAssignmentAppState();
}

class _EdencrewAssignmentAppState extends State<EdencrewAssignmentApp> {
  final StockRepository _repository = StockRepository();
  late final FavoritesState _favorites = FavoritesState(_repository);

  @override
  void dispose() {
    _favorites.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      favorites: _favorites,
      repository: _repository,
      child: MaterialApp(
        title: '이든크루 평가 과제',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}
