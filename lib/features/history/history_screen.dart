import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/spotify/spotify_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/gradient_backdrop.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/star_picker.dart';
import 'history_providers.dart';

/// 04 재생 기록 — 내 Spotify 계정을 연동하면 최근에 들은 곡을 보고 바로 평가할 수 있어요.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(spotifyLinkProvider);
    final connected = link.value ?? false;
    return GradientBackdrop(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('방금 들은 곡', style: AppText.display(28)),
            const SizedBox(height: 4),
            Text('별을 눌러서 바로 평가하세요', style: AppText.gothic(13, color: AppColors.white70)),
            const SizedBox(height: 14),
            Expanded(child: connected ? const _PlayedList() : const _ConnectGuide()),
          ]),
        ),
      ),
    );
  }
}

/// 연동 전 안내 + 연동 버튼.
class _ConnectGuide extends ConsumerStatefulWidget {
  const _ConnectGuide();

  @override
  ConsumerState<_ConnectGuide> createState() => _ConnectGuideState();
}

class _ConnectGuideState extends ConsumerState<_ConnectGuide> {
  bool _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      await ref.read(spotifyLinkProvider.notifier).connect();
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.userMessage : 'Spotify 연동에 실패했어요. 다시 시도해 주세요.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 100),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SvgPicture.asset('assets/images/icon_clock.svg',
                width: 30, height: 30, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn)),
          ),
          const SizedBox(height: 16),
          AdaptiveColor(onDark: Colors.white, onLight: AppColors.textPrimary, builder: (_, c) => Text('Spotify 연동하면 볼 수 있어요', style: AppText.mixed(16, weight: FontWeight.w800, color: c))),
          const SizedBox(height: 6),
          AdaptiveColor(
            onDark: AppColors.white75,
            onLight: AppColors.textSecondary,
            builder: (_, c) => Text('최근에 들은 곡을 바로 평가할 수 있어요.\n연동은 설정에서 언제든 해제할 수 있어요.',
                textAlign: TextAlign.center, style: AppText.gothic(13, color: c, height: 1.5)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 240,
            child: PrimaryButton(
              label: 'Spotify 연동하기',
              background: AppColors.spotifyGreen,
              foreground: const Color(0xFF0B0B0B),
              loading: _busy,
              leading: SvgPicture.asset('assets/images/spotify_logo.svg', width: 20, height: 20),
              onPressed: _connect,
            ),
          ),
        ]),
      ),
    );
  }
}

class _PlayedList extends ConsumerWidget {
  const _PlayedList();

  String _time(DateTime t, bool first) {
    final now = DateTime.now();
    final l = t.toLocal();
    if (first && now.difference(l).inMinutes < 10) return '지금';
    final hm = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    final today = l.year == now.year && l.month == now.month && l.day == now.day;
    return today ? hm : '${l.month}/${l.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final played = ref.watch(recentlyPlayedProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 110;
    return played.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lavender)),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e is ApiException ? e.userMessage : '기록을 불러올 수 없어요.',
                textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
            TextButton(onPressed: () => ref.read(recentlyPlayedProvider.notifier).reload(), child: const Text('다시 시도')),
          ]),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Text('최근에 들은 곡이 없어요.\nSpotify에서 음악을 들으면 여기에 나타나요.',
                  textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(recentlyPlayedProvider.notifier).reload(),
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: bottom),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _Row(played: list[i], timeLabel: _time(list[i].playedAt, i == 0), highlight: i == 0),
          ),
        );
      },
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.played, required this.timeLabel, required this.highlight});

  final PlayedTrack played;
  final String timeLabel;
  final bool highlight;

  Future<void> _rate(BuildContext context, WidgetRef ref, double v) async {
    try {
      await ref.read(recentlyPlayedProvider.notifier).rate(played, v);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = played.track;
    final rating = played.myReview?.rating ?? 0;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 40,
        child: Column(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: highlight ? AppColors.lavender : AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Text(timeLabel,
              style: highlight
                  ? AppText.gothic(11, weight: FontWeight.w600)
                  : AppText.grotesk(11, weight: FontWeight.w500, color: AppColors.textSecondary)),
        ]),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: () => context.push(Routes.item('track', t.id)),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.cover),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CoverImage(url: t.imageUrl, size: 44, radius: 10, seed: t.id),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (t.subtitle != null)
                      Text(t.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mixed(12, color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                StarPicker(value: rating, onChanged: (v) => _rate(context, ref, v)),
                const SizedBox(width: 8),
                Text(
                  rating == 0 ? '탭해서 평가' : rating.toStringAsFixed(1),
                  style: rating == 0
                      ? AppText.gothic(12, weight: FontWeight.w500, color: AppColors.textSecondary)
                      : AppText.grotesk(13, weight: FontWeight.w700, color: const Color(0xFF672BF4)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}
