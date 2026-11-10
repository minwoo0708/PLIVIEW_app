/// 리뷰 대상 타입. JSON은 대문자, URL 경로는 소문자를 씁니다.
enum ItemType {
  track('TRACK', 'track', '곡'),
  album('ALBUM', 'album', '앨범'),
  playlist('PLAYLIST', 'playlist', '플리');

  const ItemType(this.json, this.path, this.label);

  final String json;
  final String path;
  final String label;

  static ItemType fromJson(String value) =>
      ItemType.values.firstWhere((t) => t.json == value.toUpperCase());
}

/// 리뷰에 함께 저장하는 표시용 정보 (Spotify에서 받은 그대로).
class ReviewItem {
  const ReviewItem({required this.name, this.subtitle, this.imageUrl});

  final String name;

  /// 곡·앨범이면 아티스트, 플리면 주인 이름.
  final String? subtitle;
  final String? imageUrl;

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        name: json['name'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (subtitle != null && subtitle!.isNotEmpty) 'subtitle': subtitle,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      };
}

class PlaylistScores {
  const PlaylistScores({
    required this.concept,
    required this.flow,
    required this.discovery,
    this.snapshotId,
    this.ownerSpotifyId,
  });

  final double concept;
  final double flow;
  final double discovery;
  final String? snapshotId;
  final String? ownerSpotifyId;

  factory PlaylistScores.fromJson(Map<String, dynamic> json) => PlaylistScores(
        concept: (json['concept'] as num).toDouble(),
        flow: (json['flow'] as num).toDouble(),
        discovery: (json['discovery'] as num).toDouble(),
        snapshotId: json['snapshotId'] as String?,
        ownerSpotifyId: json['ownerSpotifyId'] as String?,
      );
}

class ReviewAuthor {
  const ReviewAuthor({required this.id, required this.nickname, this.profileImageUrl});

  final int id;
  final String nickname;
  final String? profileImageUrl;

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) => ReviewAuthor(
        id: (json['id'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        profileImageUrl: json['profileImageUrl'] as String?,
      );
}

class Review {
  const Review({
    required this.id,
    required this.type,
    required this.spotifyId,
    required this.item,
    required this.rating,
    required this.tags,
    required this.author,
    required this.isMine,
    required this.createdAt,
    this.comment,
    this.playlistScores,
    this.highlights,
  });

  final int id;
  final ItemType type;
  final String spotifyId;
  final ReviewItem item;
  final double rating;
  final String? comment;
  final List<String> tags;
  final PlaylistScores? playlistScores;

  /// 앨범·플리 리뷰의 하이라이트(최고/워스트/과소평가 곡, 최고의 순간, 전체 평가). 곡 리뷰면 null.
  final ReviewHighlights? highlights;
  final ReviewAuthor author;
  final bool isMine;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as num).toInt(),
        type: ItemType.fromJson(json['type'] as String),
        spotifyId: json['spotifyId'] as String,
        item: ReviewItem.fromJson(json['item'] as Map<String, dynamic>),
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String?,
        tags: (json['tags'] as List? ?? const []).cast<String>(),
        playlistScores: json['playlistScores'] == null
            ? null
            : PlaylistScores.fromJson(json['playlistScores'] as Map<String, dynamic>),
        highlights: json['highlights'] == null
            ? null
            : ReviewHighlights.fromJson(json['highlights'] as Map<String, dynamic>),
        author: ReviewAuthor.fromJson(json['author'] as Map<String, dynamic>),
        isMine: json['isMine'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// 하이라이트에서 고른 곡 `{spotifyId, name}`.
class TrackRef {
  const TrackRef({required this.spotifyId, required this.name});

  final String spotifyId;
  final String name;

  factory TrackRef.fromJson(Map<String, dynamic> json) =>
      TrackRef(spotifyId: json['spotifyId'] as String, name: json['name'] as String? ?? '');

  Map<String, dynamic> toJson() => {'spotifyId': spotifyId, 'name': name};
}

/// 앨범·플리 리뷰의 하이라이트. 값은 각각 없으면 null.
class ReviewHighlights {
  const ReviewHighlights({this.bestTrack, this.worstTrack, this.underratedTrack, this.bestMoment, this.body});

  final TrackRef? bestTrack;
  final TrackRef? worstTrack;
  final TrackRef? underratedTrack;
  final String? bestMoment;
  final String? body;

  bool get isEmpty =>
      bestTrack == null && worstTrack == null && underratedTrack == null && bestMoment == null && body == null;

  factory ReviewHighlights.fromJson(Map<String, dynamic> json) {
    TrackRef? track(String key) => json[key] == null ? null : TrackRef.fromJson(json[key] as Map<String, dynamic>);
    return ReviewHighlights(
      bestTrack: track('bestTrack'),
      worstTrack: track('worstTrack'),
      underratedTrack: track('underratedTrack'),
      bestMoment: json['bestMoment'] as String?,
      body: json['body'] as String?,
    );
  }
}
