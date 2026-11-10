import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/start_screen.dart';
import '../../features/placeholder/tab_placeholder.dart';
import '../../shared/widgets/main_shell.dart';
import '../auth/auth_controller.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const start = '/start';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const search = '/search';
  static const history = '/history';
  static const me = '/me';
}

/// 로그인 상태가 바뀔 때 라우터가 redirect를 다시 계산하게 하는 다리.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      const publicRoutes = {Routes.start, Routes.login, Routes.signup};

      if (auth is AuthLoading) return loc == Routes.splash ? null : Routes.splash;
      if (auth is SignedOut) return publicRoutes.contains(loc) ? null : Routes.start;
      // 로그인 상태: 인증 화면에 머물지 않고 홈으로
      if (loc == Routes.splash || publicRoutes.contains(loc)) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.start, builder: (_, _) => const StartScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const TabPlaceholder(title: '홈')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, builder: (_, _) => const TabPlaceholder(title: '탐색')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.history, builder: (_, _) => const TabPlaceholder(title: '기록')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.me, builder: (_, _) => const TabPlaceholder(title: '나')),
          ]),
        ],
      ),
    ],
  );
});
