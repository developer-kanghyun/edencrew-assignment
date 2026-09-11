import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'watchlist_screen.dart';

/// 관심 / 검색 두 탭을 감싸는 껍데기 화면.
///
/// `Navigator.push`로 화면을 바꾸지 않고 [IndexedStack]으로 둘 다 살려둔다.
/// 탭을 옮겼다 돌아와도 검색어와 스크롤 위치가 남는다.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: const <Widget>[WatchlistScreen(), _SearchPlaceholder()],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onSelected: (int index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// 검색 화면을 붙이기 전까지 탭 전환만 확인하기 위한 자리.
class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
