import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/review.dart';
import '../../core/router/app_router.dart';
import '../../core/spotify/spotify_auth.dart';
import '../../core/spotify/spotify_user_api.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/cover_image.dart';
import '../../shared/widgets/gradient_backdrop.dart';
import '../../shared/widgets/primary_button.dart';
import '../profile/profile_providers.dart';

const _ratingOptions = [3.0, 3.5, 4.0, 4.5, 5.0];

/// 내 취향 플리 만들기: 내가 높게 평가한 곡을 모아 Spotify 플리로 만들어요.
/// ① n점 이상 ② 곡마다 체크로 직접 고르기 — 둘을 함께 쓸 수 있어요.
class PlaylistMakerScreen extends ConsumerStatefulWidget {
  const PlaylistMakerScreen({super.key});

  @override
  ConsumerState<PlaylistMakerScreen> createState() => _PlaylistMakerScreenState();
}

class _PlaylistMakerScreenState extends ConsumerState<PlaylistMakerScreen> {
  double _minRating = 4.5;
  final Set<String> _unchecked = {}; // 직접 뺀 곡
  final _name = TextEditingController(text: '내가 좋아하는 곡들');
  bool _public = false;
  bool _creating = false;
  String? _error;
  String? _doneUrl;
  int _doneCount = 0;


  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }


  List<Review> _visible(List<Review> all) {
    return all.where((r) {
      if (r.rating < _minRating) return false;
      return true;
    }).toList();
  }

  Future<void> _create(List<Review> chosen) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '플리 이름을 입력해 주세요.');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    final api = ref.read(spotifyUserApiProvider);
    try {
      final playlist = await api.createPlaylist(
        name: name,
        public: _public,
        description: 'PLIVIEW에서 내가 높게 평가한 곡들',
      );
      await api.addTracks(playlist.id, chosen.map((r) => r.spotifyId).toList());
      if (!mounted) return;
      setState(() {
        _creating = false;
        _doneUrl = playlist.url ?? 'https://open.spotify.com/playlist/${playlist.id}';
        _doneCount = chosen.length;
      });
    } on SpotifyScopeException {
      if (!mounted) return;
      setState(() => _creating = false);
      _askRelink();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.userMessage;
      });
    }
  }

  /// 플리 만들기 권한이 없는 예전 연동이면 다시 연동하도록 안내해요.
  Future<void> _askRelink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Spotify 권한이 더 필요해요', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text('플리를 만들려면 Spotify를 한 번 다시 연동해야 해요.\n허용 화면에서 "동의"를 눌러 주세요.',
            style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('다시 연동')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(spotifyLinkProvider.notifier).connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('다시 연동했어요. 한 번 더 만들어 주세요.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.userMessage : 'Spotify 연동에 실패했어요. 다시 시도해 주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final linked = me?.spotify != null;
    final reviews = me == null ? null : ref.watch(allUserReviewsProvider(me.id));
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      body: GradientBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.me)),
              ),
              const SizedBox(height: 14),
              Text('내 취향 플리\n만들기', style: AppText.display(30, height: 38 / 30)),
              const SizedBox(height: 8),
              Text('높게 평가한 곡을 모아 내 Spotify에 플리로 만들어요', style: AppText.gothic(13, color: AppColors.white75)),
              const SizedBox(height: 18),
              if (!linked)
                _notice('Spotify를 연동해야 플리를 만들 수 있어요.', action: '설정', onTap: () => context.push(Routes.settings))
              else if (reviews == null)
                const SizedBox.shrink()
              else
                reviews.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.lavender)),
                  ),
                  error: (e, _) => _notice(e is ApiException ? e.userMessage : '리뷰를 불러올 수 없어요.'),
                  data: (all) {
                    final tracks = all.where((r) => r.type == ItemType.track).toList();
                    if (tracks.isEmpty) return _notice('아직 평가한 곡이 없어요. 곡을 평가하고 다시 와 주세요.');
                    return _body(tracks);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice(String text, {String? action, VoidCallback? onTap}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white14, borderRadius: BorderRadius.circular(AppRadius.cover)),
        child: Row(children: [
          Expanded(child: Text(text, style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.white85))),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action, style: AppText.gothic(13, weight: FontWeight.w800, color: AppColors.lavender)),
            ),
        ]),
      );

  Widget _body(List<Review> tracks) {
    final visible = _visible(tracks);
    final chosen = visible.where((r) => !_unchecked.contains(r.spotifyId)).toList();

    if (_doneUrl != null) return _done();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _section('① 별점 기준'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in _ratingOptions)
          _chip('${r.toStringAsFixed(1)}점 이상', _minRating == r, () => setState(() => _minRating = r)),
      ]),
      const SizedBox(height: 18),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _section('② 곡 고르기 (${chosen.length}/${visible.length})', padding: false)),
        GestureDetector(
          onTap: () => setState(() {
            if (chosen.length == visible.length) {
              _unchecked.addAll(visible.map((r) => r.spotifyId));
            } else {
              _unchecked.removeAll(visible.map((r) => r.spotifyId));
            }
          }),
          child: Text(chosen.length == visible.length ? '전체 해제' : '전체 선택',
              style: AppText.gothic(12, weight: FontWeight.w700, color: AppColors.lavender)),
        ),
      ]),
      const SizedBox(height: 8),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('조건에 맞는 곡이 없어요.\n기준 별점을 낮춰 보세요.',
                textAlign: TextAlign.center, style: AppText.gothic(13, color: AppColors.textSecondary, height: 1.5)),
          ),
        )
      else
        for (final r in visible) _trackRow(r),
      const SizedBox(height: 18),
      _section('플리 이름'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cover),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _name,
          maxLength: 100,
          style: AppText.gothic(14, weight: FontWeight.w600, color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: Text(_public ? '공개 플리로 만들어요' : '나만 보는 비공개 플리로 만들어요',
              style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        Switch(value: _public, activeThumbColor: AppColors.primary, onChanged: (v) => setState(() => _public = v)),
      ]),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_error!, style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.errorOnLight)),
        ),
      const SizedBox(height: 14),
      PrimaryButton(
        label: chosen.isEmpty ? '곡을 골라 주세요' : '${chosen.length}곡으로 플리 만들기',
        background: AppColors.primary,
        foreground: Colors.white,
        loading: _creating,
        onPressed: chosen.isEmpty ? null : () => _create(chosen),
      ),
    ]);
  }

  Widget _done() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
          Text('플리를 만들었어요!', style: AppText.display(22, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('$_doneCount곡이 Spotify에 담겼어요', style: AppText.gothic(13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Spotify에서 열기',
            background: AppColors.spotifyGreen,
            foreground: const Color(0xFF0B0B0B),
            onPressed: () => launchUrl(Uri.parse(_doneUrl!), mode: LaunchMode.externalApplication),
          ),
        ]),
      );

  Widget _section(String text, {bool padding = true}) => Padding(
        padding: EdgeInsets.only(bottom: padding ? 10 : 0),
        child: AdaptiveColor(
          onDark: Colors.white,
          onLight: AppColors.textPrimary,
          builder: (_, c) => Text(text, style: AppText.gothic(15, weight: FontWeight.w800, color: c)),
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.lavender : AppColors.white16,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              style: AppText.gothic(13, weight: FontWeight.w800, color: selected ? AppColors.ink : Colors.white)),
        ),
      );

  Widget _trackRow(Review r) {
    final checked = !_unchecked.contains(r.spotifyId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => checked ? _unchecked.add(r.spotifyId) : _unchecked.remove(r.spotifyId)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.cover),
            border: Border.all(color: checked ? AppColors.primary : AppColors.border),
          ),
          child: Row(children: [
            Icon(checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: checked ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(width: 10),
            CoverImage(url: r.item.imageUrl, size: 48, radius: 10, seed: r.spotifyId),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                if (r.item.subtitle != null)
                  Text(r.item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mixed(12, color: AppColors.textSecondary)),
              ]),
            ),
            Text('★ ${r.rating.toStringAsFixed(1)}', style: AppText.mixed(13, weight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ),
      ),
    );
  }
}
