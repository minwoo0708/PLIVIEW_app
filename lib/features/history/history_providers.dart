import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/spotify/spotify_auth.dart';

class PlayedTrack {
  const PlayedTrack({required this.track, required this.playedAt, this.myReview});

  final SpotifyItem track;
  final DateTime playedAt;
  final Review? myReview;

  PlayedTrack withReview(Review r) => PlayedTrack(track: track, playedAt: playedAt, myReview: r);
}

/// "내 Spotify 계정"이 필요한 최근 재생 목록. 앱이 Spotify에 직접 요청합니다.
class RecentlyPlayedNotifier extends AsyncNotifier<List<PlayedTrack>> {
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.spotify.com', connectTimeout: const Duration(seconds: 10)));

  @override
  Future<List<PlayedTrack>> build() async {
    final connected = ref.watch(spotifyLinkProvider).value ?? false;
    if (!connected) return const [];
    return _load();
  }

  Future<List<PlayedTrack>> _load() async {
    final token = await ref.read(spotifyAuthProvider).accessToken();
    if (token == null) {
      await ref.read(spotifyLinkProvider.notifier).refresh();
      return const [];
    }
    final Response res;
    try {
      res = await _dio.get('/v1/me/player/recently-played',
          queryParameters: {'limit': 30}, options: Options(headers: {'Authorization': 'Bearer $token'}));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        await ref.read(spotifyAuthProvider).disconnect();
        await ref.read(spotifyLinkProvider.notifier).refresh();
        return const [];
      }
      if (code == 403) {
        throw ApiException(
          status: 403,
          code: 'SPOTIFY_FORBIDDEN',
          message: '이 Spotify 계정은 아직 사용할 수 없어요. 개발 모드라 등록된 계정만 연동돼요.',
        );
      }
      if (code == 429) {
        throw ApiException(status: 429, code: 'SPOTIFY_RATE_LIMITED', message: '요청이 많아요. 잠시 후 다시 시도해 주세요.');
      }
      throw ApiException(status: code ?? 0, code: 'SPOTIFY_UNAVAILABLE', message: 'Spotify에서 기록을 불러올 수 없어요.');
    }

    // 같은 곡을 여러 번 들었으면 가장 최근 한 번만 보여 줍니다.
    final seen = <String>{};
    final played = <PlayedTrack>[];
    for (final item in (res.data['items'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      final trackJson = item['track'];
      if (trackJson is! Map<String, dynamic> || trackJson['id'] == null) continue;
      final track = SpotifyItem.fromJson(trackJson, 'track');
      if (!seen.add(track.id)) continue;
      played.add(PlayedTrack(track: track, playedAt: DateTime.tryParse(item['played_at'] as String? ?? '') ?? DateTime.now()));
    }

    // 이미 평가한 곡에는 내 별점을 붙입니다.
    try {
      final mine = await ref.read(musicRepositoryProvider).myReviews(ItemType.track, played.map((p) => p.track.id).toList());
      return [for (final p in played) mine[p.track.id] != null ? p.withReview(mine[p.track.id]!) : p];
    } on ApiException {
      return played;
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// 별을 눌러 바로 평가: 없으면 새로 만들고, 있으면 별점만 고칩니다.
  Future<void> rate(PlayedTrack p, double rating) async {
    final repo = ref.read(musicRepositoryProvider);
    final Review saved;
    if (p.myReview == null) {
      saved = await repo.createReview({
        'type': ItemType.track.json,
        'spotifyId': p.track.id,
        'item': p.track.toReviewItem().toJson(),
        'rating': rating,
      });
    } else {
      saved = await repo.updateReview(p.myReview!.id, {'rating': rating});
    }
    final list = state.value ?? const [];
    state = AsyncValue.data([for (final x in list) x.track.id == p.track.id ? x.withReview(saved) : x]);
  }
}

final recentlyPlayedProvider =
    AsyncNotifierProvider<RecentlyPlayedNotifier, List<PlayedTrack>>(RecentlyPlayedNotifier.new);
