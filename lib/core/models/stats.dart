import 'review.dart';
import 'user.dart';

/// 별점 분포 키 "0.5" ~ "5.0" (10칸).
const ratingSteps = ['0.5', '1.0', '1.5', '2.0', '2.5', '3.0', '3.5', '4.0', '4.5', '5.0'];

Map<String, int> _distribution(Object? json) {
  final map = (json as Map?) ?? const {};
  return {for (final k in ratingSteps) k: (map[k] as num?)?.toInt() ?? 0};
}

double? _toDouble(Object? v) => (v as num?)?.toDouble();

/// `GET /api/items/{type}/{id}/summary`
class ItemSummary {
  const ItemSummary({
    required this.reviewCount,
    required this.ratingDistribution,
    this.averageRating,
    this.concept,
    this.flow,
    this.discovery,
    this.myReview,
  });

  final int reviewCount;
  final double? averageRating;
  final Map<String, int> ratingDistribution;
  final double? concept;
  final double? flow;
  final double? discovery;
  final Review? myReview;

  factory ItemSummary.fromJson(Map<String, dynamic> json) {
    final avgs = json['playlistAverages'] as Map<String, dynamic>?;
    return ItemSummary(
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      averageRating: _toDouble(json['averageRating']),
      ratingDistribution: _distribution(json['ratingDistribution']),
      concept: _toDouble(avgs?['concept']),
      flow: _toDouble(avgs?['flow']),
      discovery: _toDouble(avgs?['discovery']),
      myReview: json['myReview'] == null
          ? null
          : Review.fromJson(json['myReview'] as Map<String, dynamic>),
    );
  }
}

/// `GET /api/feed/popular` 항목.
class PopularItem {
  const PopularItem({
    required this.type,
    required this.spotifyId,
    required this.item,
    required this.reviewCount,
    this.averageRating,
  });

  final ItemType type;
  final String spotifyId;
  final ReviewItem item;
  final int reviewCount;
  final double? averageRating;

  factory PopularItem.fromJson(Map<String, dynamic> json) => PopularItem(
        type: json['type'] == null ? ItemType.playlist : ItemType.fromJson(json['type'] as String), // 이번 주의 플리 응답에는 type이 없어요
        spotifyId: json['spotifyId'] as String,
        item: ReviewItem.fromJson(json['item'] as Map<String, dynamic>),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        averageRating: _toDouble(json['averageRating']),
      );
}

/// `GET /api/users/{id}/reviews` 의 stats.
class UserStats {
  const UserStats({
    required this.reviewCount,
    required this.ratingDistribution,
    required this.countByType,
    this.averageRating,
  });

  final int reviewCount;
  final double? averageRating;
  final Map<String, int> ratingDistribution;
  final Map<ItemType, int> countByType;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final byType = (json['countByType'] as Map?) ?? const {};
    return UserStats(
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      averageRating: _toDouble(json['averageRating']),
      ratingDistribution: _distribution(json['ratingDistribution']),
      countByType: {
        for (final t in ItemType.values) t: (byType[t.json] as num?)?.toInt() ?? 0,
      },
    );
  }
}

class UserProfile {
  const UserProfile({required this.user, required this.stats});

  final User user;
  final UserStats stats;
}

/// 큐레이터 평균 점수(컨셉·흐름·발견성).
class CuratorScores {
  const CuratorScores({this.concept, this.flow, this.discovery});

  final double? concept;
  final double? flow;
  final double? discovery;

  factory CuratorScores.fromJson(Map<String, dynamic>? json) => CuratorScores(
        concept: _toDouble(json?['concept']),
        flow: _toDouble(json?['flow']),
        discovery: _toDouble(json?['discovery']),
      );
}

/// 베스트 큐레이터 한 명 (`GET /api/curators/ranking` 항목, `GET /api/curators/{userId}` 응답).
/// Spotify를 연동한 PLIVIEW 사용자만 큐레이터가 됩니다.
class CuratorRank {
  const CuratorRank({
    required this.userId,
    required this.nickname,
    required this.spotifyUserId,
    required this.playlistCount,
    required this.reviewCount,
    required this.scores,
    this.rank,
    this.profileImageUrl,
    this.spotifyDisplayName,
    this.averageRating,
  });

  /// 프로필 응답에는 순위가 없어서 null일 수 있어요.
  final int? rank;
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final String spotifyUserId;
  final String? spotifyDisplayName;
  final int playlistCount;
  final int reviewCount;

  /// 받은 리뷰가 없으면 null.
  final double? averageRating;
  final CuratorScores scores;

  factory CuratorRank.fromJson(Map<String, dynamic> json) => CuratorRank(
        rank: (json['rank'] as num?)?.toInt(),
        userId: (json['userId'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        profileImageUrl: json['profileImageUrl'] as String?,
        spotifyUserId: json['spotifyUserId'] as String? ?? '',
        spotifyDisplayName: json['spotifyDisplayName'] as String?,
        playlistCount: (json['playlistCount'] as num?)?.toInt() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        averageRating: _toDouble(json['averageRating']),
        scores: CuratorScores.fromJson(json['averageScores'] as Map<String, dynamic>?),
      );
}

/// `GET /api/items/tracks/ratings` 항목: 곡 하나의 평점.
class TrackRating {
  const TrackRating({required this.spotifyId, required this.reviewCount, this.averageRating, this.myRating});

  final String spotifyId;
  final int reviewCount;
  final double? averageRating;
  final double? myRating;

  factory TrackRating.fromJson(Map<String, dynamic> json) => TrackRating(
        spotifyId: json['spotifyId'] as String,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        averageRating: _toDouble(json['averageRating']),
        myRating: _toDouble(json['myRating']),
      );
}
