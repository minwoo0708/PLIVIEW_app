import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'floating_nav.dart';

/// 하단 내비가 있는 메인 화면 틀. 탭 화면은 [navigationShell]이 보여 줍니다.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 20,
            right: 20,
            bottom: (bottomInset > 0 ? bottomInset : 12) + 8,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: FloatingNav(
                  currentIndex: navigationShell.currentIndex,
                  onSelected: (i) => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
