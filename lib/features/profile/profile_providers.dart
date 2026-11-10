import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/music_repository.dart';
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
final curatorRankingProvider = FutureProvider.autoDispose<List<CuratorRank>>((ref) {
  // 리뷰가 적은 초기에도 보이도록 1개 이상부터 보여 줍니다.
  return ref.watch(musicRepositoryProvider).curatorRanking(minReviews: 1, limit: 30);
});

/// 한 유저의 리뷰 전체(별점 모아보기용). 서버가 한 번에 50개까지만 줘서 끝날 때까지 이어서 받아요.
final allUserReviewsProvider = FutureProvider.autoDispose.family<List<Review>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final all = <Review>[];
  for (var page = 0; page < 20; page++) {
    final json = await api.get('/api/users/$userId/reviews', query: {'size': 50, 'page': page}) as Map<String, dynamic>;
    final result = PageResult.fromJson(json['reviews'] as Map<String, dynamic>, Review.fromJson);
    all.addAll(result.content);
    if (!result.hasNext) break;
  }
  return all;
});

/// 별점 막대·모아보기가 쓰는 구간: 5점 = 5.0, 4점 = 4.0~4.5, … 1점 = 0.5~1.5.
int starBucket(double rating) => rating.floor().clamp(1, 5);

/// 큐레이터 프로필(`GET /api/curators/{userId}`).
final curatorProfileProvider = FutureProvider.autoDispose.family<CuratorRank, int>((ref, userId) {
  return ref.watch(musicRepositoryProvider).curatorProfile(userId);
});

/// 큐레이터의 플리 목록(인기순, 첫 페이지).
final curatorPlaylistsProvider = FutureProvider.autoDispose.family<List<PopularItem>, int>((ref, userId) async {
  final page = await ref.watch(musicRepositoryProvider).curatorPlaylists(userId, size: 30);
  return page.content;
});
