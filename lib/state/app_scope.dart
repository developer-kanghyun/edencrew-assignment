import 'package:flutter/widgets.dart';

import 'favorites_state.dart';

/// 앱 전역에서 공유하는 객체를 위젯 트리 아래로 전달한다.
///
/// `MaterialApp`보다 **바깥**에 두어야 한다. `MaterialApp`은 내부에 `Navigator`를
/// 만들고 `Navigator.push`로 열린 화면은 그 아래에 생기므로, 바깥에 두어야 push된
/// 화면에서도 찾을 수 있다. `home:` 안에 두면 상세 화면에서 찾지 못한다.
class AppScope extends InheritedWidget {
  const AppScope({required this.favorites, required super.child, super.key});

  final FavoritesState favorites;

  static AppScope of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(
      scope != null,
      'AppScope를 찾을 수 없습니다. MaterialApp을 AppScope로 감쌌는지 확인하세요.',
    );
    return scope!;
  }

  /// 보관하는 인스턴스가 바뀌지 않으므로 이 위젯 때문에 다시 그릴 일은 없다.
  /// 값이 바뀌었을 때 다시 그리는 일은 `ListenableBuilder`가 맡는다.
  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
