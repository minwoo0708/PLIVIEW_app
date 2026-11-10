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
        type: ItemType.fromJson(json['type'] as String),
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

/// `GET /api/curators/ranking` 항목.
class CuratorRank {
  const CuratorRank({
    required this.rank,
    required this.ownerSpotifyId,
    required this.ownerName,
    required this.playlistCount,
    required this.reviewCount,
    required this.averageRating,
    this.concept,
    this.flow,
    this.discovery,
  });

  final int rank;
  final String ownerSpotifyId;
  final String ownerName;
  final int playlistCount;
  final int reviewCount;
  final double averageRating;
  final double? concept;
  final double? flow;
  final double? discovery;

  factory CuratorRank.fromJson(Map<String, dynamic> json) {
    final scores = json['averageScores'] as Map<String, dynamic>?;
    return CuratorRank(
      rank: (json['rank'] as num).toInt(),
      ownerSpotifyId: json['ownerSpotifyId'] as String,
      ownerName: json['ownerName'] as String? ?? json['ownerSpotifyId'] as String,
      playlistCount: (json['playlistCount'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num).toDouble(),
      concept: _toDouble(scores?['concept']),
      flow: _toDouble(scores?['flow']),
      discovery: _toDouble(scores?['discovery']),
    );
  }
}
