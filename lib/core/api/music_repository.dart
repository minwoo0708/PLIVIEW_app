import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_result.dart';
import '../models/review.dart';
import '../models/spotify_item.dart';
import '../models/stats.dart';
import '../models/user.dart';
import 'api_client.dart';

/// 서버의 Spotify 대리 조회, 리뷰, 항목 요약 API를 모아 둔 곳.
class MusicRepository {
  MusicRepository(this._api);

  final ApiClient _api;

  // ── Spotify 조회 ──────────────────────────────────────────

  Future<SearchPage> search(String q, String kind, {int limit = 10, int offset = 0}) async {
    final json = await _api.get('/api/spotify/search', query: {
      'q': q,
      'type': kind,
      'limit': limit,
      'offset': offset,
    });
    return SearchPage.fromJson(json as Map<String, dynamic>, kind);
  }

  Future<SpotifyItem> track(String id) async =>
      SpotifyItem.fromJson(await _api.get('/api/spotify/tracks/$id') as Map<String, dynamic>, 'track');

  Future<SpotifyItem> album(String id) async =>
      SpotifyItem.fromJson(await _api.get('/api/spotify/albums/$id') as Map<String, dynamic>, 'album');

  Future<SpotifyItem> playlist(String id) async =>
      SpotifyItem.fromJson(await _api.get('/api/spotify/playlists/$id') as Map<String, dynamic>, 'playlist');

  /// 플리 수록곡(최대 [maxTracks]곡). 서버는 한 번에 50곡씩 주고, 다음 페이지는 next가 null이 아닐 때 offset을 늘려서 받아요.
  /// 곡 객체 키가 `item` 또는 `track`일 수 있고 null 항목도 섞여 와서 거르며 읽어요.
  Future<List<SpotifyItem>> playlistTracks(String id, {int maxTracks = 200}) async {
    final tracks = <SpotifyItem>[];
    var offset = 0;
    while (tracks.length < maxTracks) {
      final json = await _api.get('/api/spotify/playlists/$id/tracks', query: {'limit': 50, 'offset': offset}) as Map<String, dynamic>;
      final entries = (json['items'] as List? ?? const []);
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final t = entry['item'] ?? entry['track'];
        if (t is Map<String, dynamic> && t['id'] != null) tracks.add(SpotifyItem.fromJson(t, 'track'));
      }
      if (json['next'] == null || entries.isEmpty) break;
      offset += 50;
    }
    return tracks;
  }

  Future<List<SpotifyItem>> artistAlbums(String id, {int limit = 10}) async {
    final json = await _api.get('/api/spotify/artists/$id/albums', query: {'limit': limit}) as Map<String, dynamic>;
    return (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] != null)
        .map((e) => SpotifyItem.fromJson(e, 'album'))
        .toList();
  }

  // ── 리뷰 ────────────────────────────────────────────────

  Future<Review> createReview(Map<String, dynamic> body) async =>
      Review.fromJson(await _api.post('/api/reviews', body: body) as Map<String, dynamic>);

  Future<Review> updateReview(int id, Map<String, dynamic> body) async =>
      Review.fromJson(await _api.patch('/api/reviews/$id', body: body) as Map<String, dynamic>);

  Future<void> deleteReview(int id) => _api.delete('/api/reviews/$id');

  /// 검색 결과에서 "이미 평가함" 표시용. 최대 50개씩.
  Future<Map<String, Review>> myReviews(ItemType type, List<String> spotifyIds) async {
    if (spotifyIds.isEmpty) return {};
    final result = <String, Review>{};
    for (var i = 0; i < spotifyIds.length; i += 50) {
      final chunk = spotifyIds.sublist(i, i + 50 > spotifyIds.length ? spotifyIds.length : i + 50);
      final json = await _api.get('/api/reviews/mine', query: {
        'type': type.json,
        'spotifyIds': chunk.join(','),
      }) as List;
      for (final r in json.whereType<Map<String, dynamic>>().map(Review.fromJson)) {
        result[r.spotifyId] = r;
      }
    }
    return result;
  }

  // ── 항목 요약·리뷰 목록 ──────────────────────────────────

  Future<ItemSummary> summary(ItemType type, String id) async =>
      ItemSummary.fromJson(await _api.get('/api/items/${type.path}/$id/summary') as Map<String, dynamic>);

  Future<PageResult<Review>> itemReviews(
    ItemType type,
    String id, {
    String sort = 'latest',
    int page = 0,
    int size = 20,
  }) async {
    final json = await _api.get('/api/items/${type.path}/$id/reviews', query: {
      'sort': sort,
      'page': page,
      'size': size,
    });
    return PageResult.fromJson(json as Map<String, dynamic>, Review.fromJson);
  }

  // ── 피드·인기·랭킹 ───────────────────────────────────────

  Future<PageResult<Review>> feed({int page = 0, int size = 20, ItemType? type}) async {
    final json = await _api.get('/api/feed', query: {'page': page, 'size': size, 'type': type?.json});
    return PageResult.fromJson(json as Map<String, dynamic>, Review.fromJson);
  }

  Future<List<PopularItem>> popular({ItemType? type, int days = 7, int limit = 10}) async {
    final json = await _api.get('/api/feed/popular', query: {
      'type': type?.json,
      'days': days,
      'limit': limit,
    }) as List;
    return json.whereType<Map<String, dynamic>>().map(PopularItem.fromJson).toList();
  }


  // ── v0.4: 곡 평점 일괄, 이번 주의 플리, 큐레이터 ───────────

  /// 곡 여러 개의 평점을 한 번에 조회합니다(최대 100개). 리뷰 없는 곡도 포함돼요.
  Future<Map<String, TrackRating>> trackRatings(List<String> spotifyIds) async {
    if (spotifyIds.isEmpty) return {};
    final result = <String, TrackRating>{};
    for (var i = 0; i < spotifyIds.length; i += 100) {
      final chunk = spotifyIds.sublist(i, i + 100 > spotifyIds.length ? spotifyIds.length : i + 100);
      final json = await _api.get('/api/items/tracks/ratings', query: {'spotifyIds': chunk.join(',')}) as List;
      for (final r in json.whereType<Map<String, dynamic>>().map(TrackRating.fromJson)) {
        result[r.spotifyId] = r;
      }
    }
    return result;
  }

  /// 이번 주의 플리: 리뷰가 [minReviews]개 이상인 플리를 평균 총점 높은 순으로. 비어 있을 수 있어요.
  Future<List<PopularItem>> weeklyPlaylists({int minReviews = 50, int limit = 10, int days = 7}) async {
    final json = await _api.get('/api/feed/weekly-playlists', query: {
      'minReviews': minReviews,
      'limit': limit,
      'days': days,
    }) as List;
    return json.whereType<Map<String, dynamic>>().map(PopularItem.fromJson).toList();
  }

  /// 베스트 큐레이터 랭킹: Spotify를 연동한 사용자만 나와요.
  Future<List<CuratorRank>> curatorRanking({int minReviews = 1, int limit = 30}) async {
    final json = await _api.get('/api/curators/ranking', query: {
      'minReviews': minReviews,
      'limit': limit,
    }) as List;
    return json.whereType<Map<String, dynamic>>().map(CuratorRank.fromJson).toList();
  }

  Future<CuratorRank> curatorProfile(int userId) async =>
      CuratorRank.fromJson(await _api.get('/api/curators/$userId') as Map<String, dynamic>);

  /// 큐레이터의 플리 목록(인기순).
  Future<PageResult<PopularItem>> curatorPlaylists(int userId, {int page = 0, int size = 20}) async {
    final json = await _api.get('/api/curators/$userId/playlists', query: {'page': page, 'size': size});
    return PageResult.fromJson(json as Map<String, dynamic>, PopularItem.fromJson);
  }

  // ── v0.4: Spotify 계정 연동 저장 ──────────────────────────

  /// PKCE로 받은 사용자 토큰을 보내 연동합니다. 서버는 토큰을 저장하지 않고 계정 id만 저장해요.
  Future<User> linkSpotify(String spotifyAccessToken) async => User.fromJson(
      await _api.put('/api/users/me/spotify', body: {'spotifyAccessToken': spotifyAccessToken}) as Map<String, dynamic>);

  Future<User> unlinkSpotify() async =>
      User.fromJson(await _api.delete('/api/users/me/spotify') as Map<String, dynamic>);
}

final musicRepositoryProvider = Provider<MusicRepository>((ref) => MusicRepository(ref.watch(apiClientProvider)));
