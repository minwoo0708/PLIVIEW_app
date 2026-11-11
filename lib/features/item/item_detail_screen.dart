import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/models/stats.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/review_card.dart';
import '../../shared/widgets/star_rating.dart';
import '../review/rate_args.dart';
import 'item_providers.dart';

/// 06 앨범(곡) 상세 / 07 플리 상세.
/// 곡은 앨범 상세 화면을 재사용하고 수록곡 목록만 숨깁니다.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.kind, required this.id});

  final String kind; // track | album | playlist
  final String id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  String _sort = 'latest';

  ItemKey get _key => (widget.kind, widget.id);
  bool get _isPlaylist => widget.kind == 'playlist';

  Future<void> _openSpotify(SpotifyItem item) async {
    final url = item.externalUrl ?? 'https://open.spotify.com/${widget.kind}/${widget.id}';
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spotify를 열 수 없어요.')));
    }
  }

  Future<void> _rate(SpotifyItem item, Review? existing) async {
    await context.push(Routes.rate, extra: RateArgs(item: item, existing: existing));
    if (mounted) refreshItem(ref, _key);
  }

  Future<void> _delete(Review r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('리뷰를 삭제할까요?', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text('삭제한 리뷰는 되돌릴 수 없어요.', style: AppText.gothic(14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.errorOnLight)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(musicRepositoryProvider).deleteReview(r.id);
      if (mounted) refreshItem(ref, _key);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(spotifyItemProvider(_key));
    final summary = ref.watch(itemSummaryProvider(_key)).asData?.value;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Container(
        color: AppColors.surface,
        child: SafeArea(
          bottom: false,
          child: itemAsync.when(
            loading: () => ColoredBox(
              color: AppColors.ink,
              child: Column(children: [
                _topBar(),
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.lavender))),
              ]),
            ),
            error: (e, _) => ColoredBox(
              color: AppColors.ink,
              child: Column(children: [
                _topBar(),
                Expanded(child: _errorView(e)),
              ]),
            ),
            data: (item) => Stack(children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(spotifyItemProvider(_key));
                  refreshItem(ref, _key);
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 위쪽 헤더만 진한 보라 그라데이션, 아래는 밝은 배경
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.ink, AppColors.inkMid, AppColors.surface],
                          stops: [0, 0.82, 1],
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _topBar(padding: EdgeInsets.zero),
                        const SizedBox(height: 14),
                        if (_isPlaylist) _playlistHead(item) else _albumHead(item),
                        const SizedBox(height: 14),
                        if (_isPlaylist) ..._playlistMetrics(summary) else ..._albumScore(summary),
                        if (!_isPlaylist) ...[
                          const SizedBox(height: 14),
                          _albumActions(item, summary),
                        ],
                      ]),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + (_isPlaylist ? 110 : 32)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (widget.kind == 'album' && item.tracks.isNotEmpty) ..._trackList(item.tracks),
                        if (_isPlaylist) ..._playlistTrackSection(),
                        const SizedBox(height: 22),
                        _reviewsSection(item),
                      ]),
                    ),
                  ],
                ),
              ),
              if (_isPlaylist)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: (bottomInset > 0 ? bottomInset : 12) + 8,
                  child: _playlistBar(item, summary),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _topBar({EdgeInsets padding = const EdgeInsets.fromLTRB(20, 0, 20, 0)}) => Padding(
        padding: padding,
        child: Align(
          alignment: Alignment.centerLeft,
          child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
        ),
      );

  Widget _errorView(Object e) {
    final msg = e is ApiException
        ? (e.code == 'SPOTIFY_NOT_FOUND' && _isPlaylist ? '불러올 수 없는 플리예요.\n비공개이거나 Spotify 공식 플리일 수 있어요.' : e.userMessage)
        : '알 수 없는 오류가 발생했어요.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(msg, textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.white85, height: 1.5)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(spotifyItemProvider(_key)),
            child: Text('다시 시도', style: AppText.gothic(14, weight: FontWeight.w700, color: AppColors.lavender)),
          ),
        ]),
      ),
    );
  }

  // ── 앨범·곡 ─────────────────────────────────────────────

  Widget _spotifyChip({double logo = 14, double font = 11, EdgeInsets? padding, Color? color}) => Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color ?? const Color(0x99000000),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset('assets/images/spotify_logo.svg', width: logo, height: logo),
          SizedBox(width: logo > 12 ? 6 : 4),
          Text('Spotify', style: AppText.grotesk(font, weight: FontWeight.w500)),
        ]),
      );

  Widget _albumHead(SpotifyItem item) {
    final year = (item.releaseDate ?? '').length >= 4 ? item.releaseDate!.substring(0, 4) : null;
    final meta = [
      ?item.subtitle,
      ?year,
      if (widget.kind == 'album' && item.totalTracks != null) '${item.totalTracks}곡',
      if (widget.kind == 'track' && item.durationMs != null) _duration(item.durationMs!),
    ].join(' · ');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 커버는 자르지 않고 정사각형 그대로 넓은 카드 가운데에 둡니다.
      Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          gradient: const LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [Color(0xFFE9E4F7), Color(0xFF2B2B3A)],
            stops: [0, 0.73],
          ),
        ),
        child: Stack(children: [
          Center(child: CoverImage(url: item.imageUrl, size: 190, radius: 18, seed: item.id)),
          Positioned(left: 14, top: 14, child: _spotifyChip()),
        ]),
      ),
      const SizedBox(height: 14),
      Text(item.name, style: AppText.display(28)),
      const SizedBox(height: 14),
      Text(meta, style: AppText.mixed(13, color: AppColors.white75)),
    ]);
  }

  List<Widget> _albumScore(ItemSummary? s) {
    final avg = s?.averageRating;
    return [
      const SizedBox(height: 14),
      if (s == null)
        const SizedBox(height: 44)
      else if (avg == null)
        Text('아직 리뷰가 없어요', style: AppText.gothic(14, color: AppColors.white75))
      else
        Row(children: [
          Text(avg.toStringAsFixed(1), style: AppText.display(34)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StarRating(value: avg),
            const SizedBox(height: 2),
            Text.rich(TextSpan(style: AppText.gothic(11, color: AppColors.white70), children: [
              TextSpan(text: '${s.reviewCount}', style: AppText.grotesk(11, color: AppColors.white70)),
              const TextSpan(text: '명이 평가했어요'),
            ])),
          ]),
        ]),
    ];
  }

  Widget _albumActions(SpotifyItem item, ItemSummary? s) {
    final mine = s?.myReview;
    return Row(children: [
      Expanded(
        child: _pill(
          color: AppColors.spotifyGreen,
          onTap: () => _openSpotify(item),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset('assets/images/spotify_logo.svg', width: 20, height: 20),
            const SizedBox(width: 8),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Spotify', style: AppText.grotesk(13, weight: FontWeight.w500, color: const Color(0xFF0B0B0B))),
              TextSpan(text: '에서 듣기', style: AppText.gothic(13, weight: FontWeight.w600, color: const Color(0xFF0B0B0B))),
            ])),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _pill(
          color: AppColors.primary,
          onTap: () => _rate(item, mine),
          child: Center(
            child: Text(mine == null ? '평가하기' : '내 평가 수정',
                style: AppText.gothic(13, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _pill({required Color color, required VoidCallback onTap, required Widget child}) => Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: SizedBox(height: 46, child: child),
        ),
      );
  /// 플리 수록곡 섹션: 불러오는 중, 불러올 수 없음(비공개·공식 플리), 곡 목록 세 가지 상태를 보여 줘요.
  List<Widget> _playlistTrackSection() {
    final tracks = ref.watch(playlistTracksProvider(widget.id));
    return tracks.when(
      loading: () => const [
        SizedBox(height: 18),
        Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary))),
      ],
      error: (e, _) => [
        const SizedBox(height: 18),
        Text('수록곡', style: AppText.gothic(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(
          e is ApiException && (e.status == 403 || e.status == 404)
              ? '불러올 수 없는 플리예요. 비공개이거나 Spotify 공식 플리일 수 있어요.'
              : (e is ApiException ? e.userMessage : '수록곡을 불러올 수 없어요.'),
          style: AppText.gothic(13, color: AppColors.textSecondary),
        ),
        TextButton(onPressed: () => ref.invalidate(playlistTracksProvider(widget.id)), child: const Text('다시 시도')),
      ],
      data: (list) => list.isEmpty ? const [] : _trackList(list),
    );
  }


  List<Widget> _trackList(List<SpotifyItem> tracks) {
    // 수록곡 평점은 서버에서 한 번에 받아요.
    final ids = tracks.map((t) => t.id).join(',');
    final ratings = ref.watch(trackRatingsProvider(ids)).asData?.value ?? const <String, TrackRating>{};
    return [
        const SizedBox(height: 18),
        Text('수록곡', style: AppText.gothic(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('곡을 누르면 곡 평가를 남길 수 있어요', style: AppText.gothic(12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        for (var i = 0; i < tracks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TrackRow(
              number: i + 1,
              track: tracks[i],
              duration: tracks[i].durationMs == null ? null : _duration(tracks[i].durationMs!),
              rating: ratings[tracks[i].id],
              onTap: () async {
                await context.push(Routes.item('track', tracks[i].id));
                // 곡 평가를 남기고 돌아오면 곡 평점을 새로 불러옵니다.
                if (mounted) ref.invalidate(trackRatingsProvider(ids));
              },
            ),
          ),
    ];
  }

  String _duration(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // ── 플리 ───────────────────────────────────────────────

  Widget _playlistHead(SpotifyItem item) {
    final summary = ref.watch(itemSummaryProvider(_key)).asData?.value;
    final mySnapshot = summary?.myReview?.playlistScores?.snapshotId;
    final outdated = mySnapshot != null && item.snapshotId != null && mySnapshot != item.snapshotId;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.display(30, height: 38 / 30)),
          const SizedBox(height: 8),
          Text(
            'by ${item.ownerName ?? item.ownerId ?? ''}',
            style: AppText.mixed(12, color: AppColors.white75),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (outdated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('수정됨', style: AppText.gothic(11, weight: FontWeight.w800, color: AppColors.ink)),
              ),
            _spotifyChip(logo: 12, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppColors.white16),
          ]),
        ]),
      ),
      const SizedBox(width: 12),
      CoverImage(url: item.imageUrl, size: 112, radius: AppRadius.card, seed: item.id),
    ]);
  }

  List<Widget> _playlistMetrics(ItemSummary? s) {
    Widget metric(String label, String value, {bool filled = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.totalBar),
              border: filled ? null : Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppText.mixed(12, weight: FontWeight.w500, color: filled ? AppColors.white85 : AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppText.display(32, color: filled ? Colors.white : AppColors.primary)),
            ]),
          ),
        );
    String f(double? v) => v == null ? '-' : v.toStringAsFixed(1);
    return [
      Row(children: [
        metric('컨셉 일치도', f(s?.concept)),
        const SizedBox(width: 10),
        metric('곡 흐름', f(s?.flow)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        metric('발견성', f(s?.discovery)),
        const SizedBox(width: 10),
        metric('총점 · ${s?.reviewCount ?? 0}명', f(s?.averageRating), filled: true),
      ]),
    ];
  }

  Widget _playlistBar(SpotifyItem item, ItemSummary? s) {
    final mine = s?.myReview;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => _openSpotify(item),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.white14, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SvgPicture.asset('assets/images/spotify_logo.svg', width: 22, height: 22),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => _rate(item, mine),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(mine == null ? '이 플리 평가하기' : '내 평가 수정',
                      style: AppText.gothic(15, weight: FontWeight.w600, color: AppColors.ink)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── 리뷰 목록 ──────────────────────────────────────────

  Widget _reviewsSection(SpotifyItem item) {
    final reviews = ref.watch(itemReviewsProvider((_key, _sort)));
    const sorts = [('latest', '최신순'), ('rating_desc', '별점 높은 순'), ('rating_asc', '별점 낮은 순')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('리뷰', style: AppText.gothic(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        for (final (value, label) in sorts)
          GestureDetector(
            onTap: () => setState(() => _sort = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _sort == value ? AppColors.ink : AppColors.chip,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(label,
                  style: AppText.gothic(12, weight: FontWeight.w700, color: _sort == value ? Colors.white : AppColors.primary)),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      reviews.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(e is ApiException ? e.userMessage : '리뷰를 불러올 수 없어요.',
              style: AppText.gothic(14, color: AppColors.textSecondary)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('첫 리뷰를 남겨 보세요', style: AppText.gothic(14, color: AppColors.textSecondary))),
            );
          }
          return Column(children: [
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewCard(
                  review: r,
                  outdated: _isPlaylist &&
                      r.playlistScores?.snapshotId != null &&
                      item.snapshotId != null &&
                      r.playlistScores!.snapshotId != item.snapshotId,
                  onEdit: () => _rate(item, r),
                  onDelete: () => _delete(r),
                ),
              ),
          ]);
        },
      ),
    ]);
  }
}

/// 수록곡 한 줄: 번호 · 곡 이름 · (모두의 평균 별점 / 내 별점) · 길이.
/// 평점은 서버의 곡별 평점 일괄 조회 결과를 받아서 보여 줍니다.
class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.number, required this.track, required this.duration, required this.rating, required this.onTap});

  final int number;
  final SpotifyItem track;
  final String? duration;
  final TrackRating? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avg = rating?.averageRating;
    final mine = rating?.myRating;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.scoreButton),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          SizedBox(
            width: 22,
            child: Text('$number', style: AppText.grotesk(13, weight: FontWeight.w500, color: AppColors.primary)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
              if (duration != null) Text(duration!, style: AppText.grotesk(11, color: AppColors.textSecondary)),
            ]),
          ),
          if (avg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('★ ${avg.toStringAsFixed(1)}',
                  style: AppText.mixed(12, weight: FontWeight.w700, color: AppColors.primary)),
            ),
          if (mine != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text('내 ${mine.toStringAsFixed(1)}',
                  style: AppText.mixed(12, weight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}
