import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/start_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/item/artist_screen.dart';
import '../../features/item/item_detail_screen.dart';
import '../../features/profile/curator_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/ranking_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/review/rate_args.dart';
import '../../features/review/rate_screen.dart';
import '../../features/search/search_screen.dart';
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
  static const rate = '/rate';
  static const settings = '/settings';
  static const ranking = '/ranking';
  static String curator(int userId) => '/curator/$userId';

  /// 상세 화면. kind는 track / album / artist / playlist.
  static String item(String kind, String id) => '/$kind/$id';
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
      // 상세·평가 화면은 하단 내비 위로 덮어서 보여 줍니다.
      GoRoute(
        path: '/track/:id',
        builder: (_, s) => ItemDetailScreen(kind: 'track', id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/album/:id',
        builder: (_, s) => ItemDetailScreen(kind: 'album', id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/playlist/:id',
        builder: (_, s) => ItemDetailScreen(kind: 'playlist', id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/artist/:id',
        builder: (_, s) => ArtistScreen(id: s.pathParameters['id']!, name: s.extra as String?),
      ),
      GoRoute(
        path: Routes.rate,
        builder: (_, s) => RateScreen(args: s.extra! as RateArgs),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.ranking, builder: (_, _) => const RankingScreen()),
      GoRoute(
        path: '/curator/:userId',
        builder: (_, s) => CuratorScreen(userId: int.parse(s.pathParameters['userId']!)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, builder: (_, _) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.me, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
