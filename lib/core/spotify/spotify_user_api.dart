import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import 'spotify_auth.dart';

/// 새 권한(플리 만들기)이 없을 때 던져요. 화면에서 "다시 연동해 주세요"로 안내합니다.
class SpotifyScopeException implements Exception {
  const SpotifyScopeException();
}

/// 사용자 본인의 Spotify 계정으로 직접 호출하는 API (서버를 거치지 않아요).
/// 토큰 값은 로그나 화면에 절대 남기지 않습니다.
class SpotifyUserApi {
  SpotifyUserApi(this._auth);

  final SpotifyAuth _auth;
  final _dio = Dio(BaseOptions(baseUrl: 'https://api.spotify.com', connectTimeout: const Duration(seconds: 10)));

  Future<Options> _options() async {
    final token = await _auth.accessToken();
    if (token == null) throw const SpotifyScopeException();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  ApiException _map(DioException e) {
    final code = e.response?.statusCode;
    if (code == 429) {
      return ApiException(status: 429, code: 'SPOTIFY_RATE_LIMITED', message: '요청이 많아요. 잠시 후 다시 시도해 주세요.');
    }
    return ApiException(
      status: code ?? 0,
      code: 'SPOTIFY_UNAVAILABLE',
      message: 'Spotify 요청에 실패했어요. (오류 ${code ?? '연결 실패'})',
    );
  }

  /// 내 계정에 새 플리를 만들고 (id, 열기 주소)를 돌려줘요.
  Future<({String id, String? url})> createPlaylist({
    required String name,
    required bool public,
    String? description,
  }) async {
    final options = await _options();
    final body = {'name': name, 'public': public, 'description': ?description};
    try {
      final res = await _dio.post('/v1/me/playlists', data: body, options: options);
      return (id: res.data['id'] as String, url: (res.data['external_urls'] as Map?)?['spotify'] as String?);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) throw const SpotifyScopeException();
      // 예전 경로로 한 번 더 시도: /v1/users/{id}/playlists
      if (code == 404 || code == 405) {
        try {
          final me = await _dio.get('/v1/me', options: options);
          final res = await _dio.post('/v1/users/${me.data['id']}/playlists', data: body, options: options);
          return (id: res.data['id'] as String, url: (res.data['external_urls'] as Map?)?['spotify'] as String?);
        } on DioException catch (e2) {
          final c2 = e2.response?.statusCode;
          if (c2 == 401 || c2 == 403) throw const SpotifyScopeException();
          throw _map(e2);
        }
      }
      throw _map(e);
    }
  }

  /// 플리에 곡을 넣어요(한 번에 100곡씩). 새 경로(/items)가 없으면 예전 경로(/tracks)로 다시 시도해요.
  Future<void> addTracks(String playlistId, List<String> trackIds) async {
    final options = await _options();
    for (var i = 0; i < trackIds.length; i += 100) {
      final chunk = trackIds.sublist(i, i + 100 > trackIds.length ? trackIds.length : i + 100);
      final data = {'uris': [for (final id in chunk) 'spotify:track:$id']};
      try {
        await _dio.post('/v1/playlists/$playlistId/items', data: data, options: options);
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) throw const SpotifyScopeException();
        if (code == 404) {
          try {
            await _dio.post('/v1/playlists/$playlistId/tracks', data: data, options: options);
            continue;
          } on DioException catch (e2) {
            final c2 = e2.response?.statusCode;
            if (c2 == 401 || c2 == 403) throw const SpotifyScopeException();
            throw _map(e2);
          }
        }
        throw _map(e);
      }
    }
  }

  /// 곡 id → 그 곡 대표 아티스트의 장르 목록.
  /// Spotify가 개발 모드에서 여러 개를 한 번에 조회하는 API를 막아서, 곡·아티스트를 하나씩 조회해요
  /// (10개씩 동시에). 실패한 곡은 건너뛰고, 모두 실패하면 빈 결과를 돌려줘요.
  Future<Map<String, List<String>>> trackGenres(List<String> trackIds) async {
    final result = <String, List<String>>{};
    try {
      final options = await _options();
      final ids = trackIds.take(100).toList();

      Future<T?> safe<T>(Future<T> Function() call) async {
        try {
          return await call();
        } on DioException catch (e) {
          if (kDebugMode) debugPrint('[SpotifyDiag] genre call ${e.requestOptions.path} -> ${e.response?.statusCode}');
          return null;
        }
      }

      // 1) 곡 → 대표 아티스트 id
      final artistOfTrack = <String, String>{};
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final responses = await Future.wait(chunk.map((id) => safe(() => _dio.get('/v1/tracks/$id', options: options))));
        for (var k = 0; k < chunk.length; k++) {
          final data = responses[k]?.data;
          final artists = data is Map ? data['artists'] as List? : null;
          if (artists != null && artists.isNotEmpty) artistOfTrack[chunk[k]] = (artists.first as Map)['id'] as String;
        }
      }

      // 2) 아티스트 → 장르 (같은 아티스트는 한 번만)
      final artistIds = artistOfTrack.values.toSet().toList();
      final genresOfArtist = <String, List<String>>{};
      for (var i = 0; i < artistIds.length; i += 10) {
        final chunk = artistIds.sublist(i, i + 10 > artistIds.length ? artistIds.length : i + 10);
        final responses = await Future.wait(chunk.map((id) => safe(() => _dio.get('/v1/artists/$id', options: options))));
        for (var k = 0; k < chunk.length; k++) {
          final data = responses[k]?.data;
          if (data is Map) genresOfArtist[chunk[k]] = (data['genres'] as List? ?? const []).cast<String>();
        }
      }
      artistOfTrack.forEach((track, artist) {
        if (genresOfArtist.containsKey(artist)) result[track] = genresOfArtist[artist]!;
      });
      if (kDebugMode) {
        debugPrint('[SpotifyDiag] genres tracks=${ids.length} artists=${artistIds.length} withGenres=${genresOfArtist.values.where((g) => g.isNotEmpty).length}');
      }
    } catch (_) {
      return const {};
    }
    return result;
  }
}

final spotifyUserApiProvider = Provider<SpotifyUserApi>((ref) => SpotifyUserApi(ref.watch(spotifyAuthProvider)));
