import 'review.dart';

/// Spotify 원본 JSON에서 앱이 쓰는 값만 뽑은 항목(곡·앨범·아티스트·플리 공통).
class SpotifyItem {
  const SpotifyItem({
    required this.id,
    required this.name,
    required this.kind,
    this.subtitle,
    this.imageUrl,
    this.externalUrl,
    this.releaseDate,
    this.durationMs,
    this.ownerId,
    this.ownerName,
    this.snapshotId,
    this.totalTracks,
    this.tracks = const [],
  });

  final String id;
  final String name;

  /// 'track' | 'album' | 'artist' | 'playlist'
  final String kind;

  /// 곡·앨범: 아티스트 이름들 / 플리: 주인 이름.
  final String? subtitle;
  final String? imageUrl;
  final String? externalUrl;
  final String? releaseDate;
  final int? durationMs;

  // 플레이리스트 전용
  final String? ownerId;
  final String? ownerName;
  final String? snapshotId;

  // 앨범 전용
  final int? totalTracks;
  final List<SpotifyItem> tracks;

  /// 리뷰 작성 때 서버로 보내는 표시용 정보.
  ReviewItem toReviewItem() => ReviewItem(name: name, subtitle: subtitle, imageUrl: imageUrl);

  static String? _image(Object? images) {
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) return first['url'] as String?;
    }
    return null;
  }

  static String? _artists(Object? artists) {
    if (artists is! List) return null;
    final names = artists.whereType<Map>().map((a) => a['name']).whereType<String>().toList();
    return names.isEmpty ? null : names.join(', ');
  }

  static String? _external(Map<String, dynamic> json) =>
      (json['external_urls'] as Map?)?['spotify'] as String?;

  /// `kind`는 'track' / 'album' / 'artist' / 'playlist'.
  factory SpotifyItem.fromJson(Map<String, dynamic> json, String kind) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final album = json['album'] as Map<String, dynamic>?;
    final tracksJson = (json['tracks'] as Map?)?['items'];
    return SpotifyItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: kind,
      subtitle: switch (kind) {
        'playlist' => owner?['display_name'] as String? ?? owner?['id'] as String?,
        'artist' => null,
        _ => _artists(json['artists']),
      },
      // 곡은 앨범 커버를 씁니다.
      imageUrl: _image(json['images']) ?? _image(album?['images']),
      externalUrl: _external(json),
      releaseDate: (json['release_date'] ?? album?['release_date']) as String?,
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      ownerId: owner?['id'] as String?,
      ownerName: owner?['display_name'] as String?,
      snapshotId: json['snapshot_id'] as String?,
      totalTracks: (json['total_tracks'] as num?)?.toInt(),
      tracks: tracksJson is List
          ? tracksJson
              .whereType<Map<String, dynamic>>()
              .where((t) => t['id'] != null)
              .map((t) => SpotifyItem.fromJson(t, 'track'))
              .toList()
          : const [],
    );
  }
}

/// 검색 결과 한 페이지.
class SearchPage {
  const SearchPage({required this.items, required this.hasNext});

  final List<SpotifyItem> items;
  final bool hasNext;

  factory SearchPage.fromJson(Map<String, dynamic> json, String kind) {
    final block = json['${kind}s'] as Map<String, dynamic>? ?? const {};
    final raw = (block['items'] as List? ?? const []);
    return SearchPage(
      // 플리 검색은 null 항목이 섞여 올 수 있습니다.
      items: raw
          .whereType<Map<String, dynamic>>()
          .where((e) => e['id'] != null)
          .map((e) => SpotifyItem.fromJson(e, kind))
          .toList(),
      hasNext: block['next'] != null,
    );
  }
}
