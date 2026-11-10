import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/page_result.dart';
import '../models/review.dart';
import '../models/spotify_item.dart';
import '../models/stats.dart';
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

  Future<List<CuratorRank>> curatorRanking({int minReviews = 3, int limit = 20}) async {
    final json = await _api.get('/api/curators/ranking', query: {
      'minReviews': minReviews,
      'limit': limit,
    }) as List;
    return json.whereType<Map<String, dynamic>>().map(CuratorRank.fromJson).toList();
  }
}

final musicRepositoryProvider = Provider<MusicRepository>((ref) => MusicRepository(ref.watch(apiClientProvider)));
