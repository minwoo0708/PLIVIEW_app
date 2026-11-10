import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/page_result.dart';
import '../../core/models/review.dart';
import '../../core/models/stats.dart';
import '../../core/models/user.dart';

class ProfileData {
  const ProfileData({required this.profile, required this.reviews});

  final UserProfile profile;
  final PageResult<Review> reviews;
}

/// `GET /api/users/{id}/reviews` — 유저 정보, 전체 통계, 최근 리뷰(최신순).
final profileProvider = FutureProvider.autoDispose.family<ProfileData, int>((ref, userId) async {
  final json = await ref.watch(apiClientProvider).get('/api/users/$userId/reviews', query: {'size': 20})
      as Map<String, dynamic>;
  return ProfileData(
    profile: UserProfile(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    ),
    reviews: PageResult.fromJson(json['reviews'] as Map<String, dynamic>, Review.fromJson),
  );
});

/// `GET /api/curators/ranking`
final curatorRankingProvider = FutureProvider.autoDispose<List<CuratorRank>>((ref) async {
  final api = ref.watch(apiClientProvider);
  // 리뷰가 적은 초기에도 보이도록 1개 이상부터 보여 줍니다.
  final json = await api.get('/api/curators/ranking', query: {'minReviews': 1, 'limit': 30}) as List;
  return json.whereType<Map<String, dynamic>>().map(CuratorRank.fromJson).toList();
});
