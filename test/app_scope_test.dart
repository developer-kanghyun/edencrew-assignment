import 'package:edencrew_assignment_starter/state/app_scope.dart';
import 'package:edencrew_assignment_starter/state/favorites_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Navigator.push로 열린 화면도 같은 FavoritesState를 찾는다', (
    WidgetTester tester,
  ) async {
    final FavoritesState favorites = FavoritesState();
    late FavoritesState fromHome;
    late FavoritesState fromPushedRoute;

    await tester.pumpWidget(
      AppScope(
        favorites: favorites,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              fromHome = AppScope.of(context).favorites;
              return TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext routeContext) {
                      fromPushedRoute = AppScope.of(routeContext).favorites;
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                child: const Text('상세로'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세로'));
    await tester.pumpAndSettle();

    expect(fromHome, same(favorites));
    expect(fromPushedRoute, same(favorites));
  });
}
