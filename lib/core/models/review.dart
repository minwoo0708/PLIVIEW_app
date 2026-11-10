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
  });

  final int id;
  final ItemType type;
  final String spotifyId;
  final ReviewItem item;
  final double rating;
  final String? comment;
  final List<String> tags;
  final PlaylistScores? playlistScores;
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
        author: ReviewAuthor.fromJson(json['author'] as Map<String, dynamic>),
        isMine: json['isMine'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
