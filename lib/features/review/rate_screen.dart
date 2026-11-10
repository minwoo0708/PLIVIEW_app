import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/cover_image.dart';
import '../item/item_providers.dart' show typeOfKind;
import '../../shared/widgets/star_rating.dart';
import 'rate_args.dart';
import 'track_picker.dart';

/// 플리 총점 = 세 점수 평균을 0.5 단위로 반올림.
/// 예: 5·4·3 → 4.0 / 5·4·4 → 4.33 → 4.5 / 3·3·4 → 3.33 → 3.5
double playlistTotal(int concept, int flow, int discovery) {
  final avg = (concept + flow + discovery) / 3;
  return (avg * 2).round() / 2;
}

const _suggestedTags = ['드라이브', '새벽감성', '집중', '운동', '감성', '신나는', '위로', '산책'];

/// 08 평가하기(곡·앨범) / 09 평가하기(플리)
class RateScreen extends ConsumerStatefulWidget {
  const RateScreen({super.key, required this.args});

  final RateArgs args;

  @override
  ConsumerState<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends ConsumerState<RateScreen> {
  late final SpotifyItem _item = widget.args.item;
  late final Review? _existing = widget.args.existing;
  bool get _isPlaylist => _item.kind == 'playlist';
  bool get _editing => _existing != null;

  final _comment = TextEditingController();
  final _tagInput = TextEditingController();
  double _rating = 0;
  int _concept = 0, _flow = 0, _discovery = 0;
  final List<String> _tags = [];

  // 앨범·플리 하이라이트 (모두 선택 항목)
  TrackRef? _bestTrack;
  TrackRef? _worstTrack;
  TrackRef? _underratedTrack;
  final _bestMoment = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    if (e != null) {
      _rating = e.rating;
      _comment.text = e.comment ?? '';
      _tags.addAll(e.tags);
      final h = e.highlights;
      if (h != null) {
        _bestTrack = h.bestTrack;
        _worstTrack = h.worstTrack;
        _underratedTrack = h.underratedTrack;
        _bestMoment.text = h.bestMoment ?? '';
        _body.text = h.body ?? '';
      }
      final s = e.playlistScores;
      if (s != null) {
        _concept = s.concept.round();
        _flow = s.flow.round();
        _discovery = s.discovery.round();
      }
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    _tagInput.dispose();
    _bestMoment.dispose();
    _body.dispose();
    super.dispose();
  }

  /// 서버로 보낼 하이라이트 값. 곡 리뷰에는 보내면 400이라 앨범·플리에서만 만듭니다.
  /// 수정할 때 최고의 순간·전체 평가는 빈 문자열을 보내면 삭제돼요(곡 선택은 교체만 가능).
  Map<String, dynamic> _highlightPayload({required bool editing}) {
    if (_item.kind == 'track') return const {};
    final moment = _bestMoment.text.trim();
    final body = _body.text.trim();
    return {
      if (_bestTrack != null) 'bestTrack': _bestTrack!.toJson(),
      if (_worstTrack != null) 'worstTrack': _worstTrack!.toJson(),
      if (_item.kind == 'album' && _underratedTrack != null) 'underratedTrack': _underratedTrack!.toJson(),
      if (moment.isNotEmpty || editing) 'bestMoment': moment,
      if (body.isNotEmpty || editing) 'body': body,
    };
  }

  double get _total => _isPlaylist ? playlistTotal(_concept, _flow, _discovery) : _rating;

  bool get _canSave =>
      !_saving && (_isPlaylist ? (_concept > 0 && _flow > 0 && _discovery > 0) : _rating > 0);

  String get _title => switch (_item.kind) {
        'track' => '이 곡,\n어땠나요?',
        'album' => '이 앨범,\n어땠나요?',
        _ => '플리는\n어땠나요?',
      };

  void _addTag(String raw) {
    final t = raw.trim().replaceFirst(RegExp(r'^#+'), '');
    if (t.isEmpty) return;
    if (t.length > 20) {
      setState(() => _error = '태그는 20자까지 쓸 수 있어요.');
      return;
    }
    if (_tags.contains(t)) return;
    if (_tags.length >= 5) {
      setState(() => _error = '태그는 5개까지 달 수 있어요.');
      return;
    }
    setState(() {
      _tags.add(t);
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(musicRepositoryProvider);
    final comment = _comment.text.trim();
    try {
      if (_editing) {
        await repo.updateReview(_existing!.id, {
          'rating': _total,
          'comment': comment, // 빈 문자열이면 한 줄 평 삭제
          'tags': _tags, // 전체 교체
          ..._highlightPayload(editing: true),
          if (_isPlaylist) ...{
            'conceptScore': _concept,
            'flowScore': _flow,
            'discoveryScore': _discovery,
            if (_item.snapshotId != null) 'snapshotId': _item.snapshotId,
          },
        });
      } else {
        await repo.createReview({
          'type': typeOfKind(_item.kind).json,
          'spotifyId': _item.id,
          'item': _item.toReviewItem().toJson(),
          'rating': _total,
          if (comment.isNotEmpty) 'comment': comment,
          if (_tags.isNotEmpty) 'tags': _tags,
          ..._highlightPayload(editing: false),
          if (_isPlaylist) ...{
            'conceptScore': _concept,
            'flowScore': _flow,
            'discoveryScore': _discovery,
            if (_item.snapshotId != null) 'snapshotId': _item.snapshotId,
            if (_item.ownerId != null) 'ownerSpotifyId': _item.ownerId,
          },
        });
      }
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.code == 'REVIEW_ALREADY_EXISTS'
            ? '이미 평가한 항목이에요. 상세 화면에서 "내 평가 수정"을 눌러 주세요.'
            : (e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.userMessage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
            stops: _isPlaylist ? const [0, 0.26, 0.40, 1] : const [0, 0.30, 0.46, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(children: [
            ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 110),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.white16, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SvgPicture.asset('assets/images/icon_close.svg', width: 22, height: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_title, style: AppText.display(30, height: 38 / 30)),
                const SizedBox(height: 14),
                _target(),
                const SizedBox(height: 14),
                if (_isPlaylist) ..._playlistForm() else ..._albumForm(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.errorOnLight)),
                  ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: (bottomInset > 0 ? bottomInset : 12) + 8,
              child: _saveBar(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _target() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(color: AppColors.white14, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CoverImage(url: _item.imageUrl, size: 32, radius: 16, seed: _item.id),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                [_item.name, if (!_isPlaylist && _item.subtitle != null) _item.subtitle!].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.mixed(13, weight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      );

  // ── 곡·앨범 ─────────────────────────────────────────────

  List<Widget> _albumForm() => [
        _ratingCard(),
        const SizedBox(height: 14),
        _commentBox(),
        // 곡 평가는 별점과 한줄평만, 태그는 앨범에서만 받아요.
        if (_item.kind != 'track') ...[
          const SizedBox(height: 14),
          _tagSection(),
          ..._highlightWidgets(),
        ],
      ];

  Widget _ratingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(26)),
      child: Column(children: [
        Text(_rating.toStringAsFixed(1), style: AppText.display(56)),
        const SizedBox(height: 8),
        // 별 위를 누르거나 드래그해서 0.5 단위로 고릅니다.
        LayoutBuilder(builder: (context, c) {
          const star = 38.0, gap = 8.0;
          const total = star * 5 + gap * 4;
          double fromDx(double dx) {
            final x = (dx - (c.maxWidth - total) / 2).clamp(0.0, total - 0.01);
            final index = (x / (star + gap)).floor(); // 몇 번째 별 위인지
            final inStar = x - index * (star + gap); // 그 별 안에서의 위치
            // 별의 왼쪽 절반은 반 별, 오른쪽 절반(과 틈)은 한 별
            return inStar < star / 2 ? index + 0.5 : index + 1.0;
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => setState(() => _rating = fromDx(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) => setState(() => _rating = fromDx(d.localPosition.dx)),
            child: Center(child: StarRating(value: _rating, size: star, gap: gap)),
          );
        }),
        const SizedBox(height: 8),
        Text.rich(TextSpan(style: AppText.gothic(12, color: const Color(0x99FFFFFF)), children: [
          TextSpan(text: '0.5', style: AppText.grotesk(12, color: const Color(0x99FFFFFF))),
          const TextSpan(text: '점 단위로 골라요'),
        ])),
      ]),
    );
  }

  Widget _commentBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cover),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('한 줄 평', style: AppText.gothic(11, weight: FontWeight.w600, color: AppColors.primary)),
            const Spacer(),
            Text('${_comment.text.characters.length}/200', style: AppText.grotesk(11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: _comment,
            maxLength: 200,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            style: AppText.gothic(14, weight: FontWeight.w500, color: AppColors.textPrimary, height: 22 / 14),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: '',
              hintText: '느낀 점을 한 줄로 남겨 보세요',
              hintStyle: AppText.gothic(14, color: AppColors.textSecondary, height: 22 / 14),
            ),
          ),
        ]),
      );

  Widget _tagSection() {
    final options = [..._tags, ..._suggestedTags.where((t) => !_tags.contains(t))];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in options)
          GestureDetector(
            onTap: () => _tags.contains(t) ? setState(() => _tags.remove(t)) : _addTag(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _tags.contains(t) ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: _tags.contains(t) ? null : Border.all(color: AppColors.border),
              ),
              child: Text('#$t',
                  style: _tags.contains(t)
                      ? AppText.gothic(13, weight: FontWeight.w800, color: Colors.white)
                      : AppText.gothic(13, weight: FontWeight.w500, color: AppColors.textPrimary)),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _tagInput,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            _addTag(v);
            _tagInput.clear();
          },
          style: AppText.gothic(13, color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            hintText: '직접 태그 추가 (최대 5개, 엔터로 추가)',
            hintStyle: AppText.gothic(13, color: AppColors.textSecondary),
          ),
        ),
      ),
    ]);
  }

  // ── 플리 ───────────────────────────────────────────────

  List<Widget> _playlistForm() => [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            _step('컨셉 일치도', '주제와 곡이 잘 맞아요', _concept, (v) => setState(() => _concept = v)),
            const SizedBox(height: 16),
            _step('곡 흐름', '전환이 매끄러워요', _flow, (v) => setState(() => _flow = v)),
            const SizedBox(height: 16),
            _step('발견성', '새로운 곡을 알았어요', _discovery, (v) => setState(() => _discovery = v)),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.totalBar)),
          child: Row(children: [
            Text('총점', style: AppText.gothic(14, weight: FontWeight.w600)),
            const Spacer(),
            StarRating(value: _total, size: 16),
            const SizedBox(width: 10),
            Text(_total.toStringAsFixed(1), style: AppText.display(22)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          SvgPicture.asset('assets/images/icon_info.svg', width: 14, height: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text('지금 버전의 플리(snapshot)로 저장돼요',
                style: AppText.mixed(12, color: AppColors.textSecondary)),
          ),
        ]),
        ..._highlightWidgets(),
      ];

  // ── 하이라이트 (앨범·플리) ─────────────────────────────

  List<Widget> _highlightWidgets() => [
        const SizedBox(height: 22),
        Text('하이라이트', style: AppText.gothic(16, weight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('모두 선택 사항이에요. 남기고 싶은 것만 채워 주세요.',
            style: AppText.gothic(12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _trackField('최고의 곡', _bestTrack, (t) => setState(() => _bestTrack = t)),
        const SizedBox(height: 10),
        _trackField('워스트 곡', _worstTrack, (t) => setState(() => _worstTrack = t)),
        // 가장 과소평가된 곡은 앨범에서만 받아요.
        if (_item.kind == 'album') ...[
          const SizedBox(height: 10),
          _trackField('가장 과소평가된 곡', _underratedTrack, (t) => setState(() => _underratedTrack = t)),
        ],
        const SizedBox(height: 10),
        _textBox('최고의 순간', '예: 2:31 브릿지', _bestMoment, maxLength: 100, maxLines: 1),
        const SizedBox(height: 10),
        _textBox('전체 평가', '앨범·플리를 들은 느낌을 길게 적어 보세요', _body, maxLength: 2000, maxLines: 8, minLines: 4),
      ];

  Widget _trackField(String label, TrackRef? value, ValueChanged<TrackRef> onPicked) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final picked = await pickTrack(context, item: _item, title: label);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cover),
          border: Border.all(color: value == null ? AppColors.border : AppColors.primary),
        ),
        child: Row(children: [
          Text(label, style: AppText.gothic(13, weight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value?.name ?? '곡 고르기',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: value == null
                  ? AppText.gothic(13, color: AppColors.textSecondary)
                  : AppText.mixed(13, weight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _textBox(String label, String hint, TextEditingController c,
      {required int maxLength, required int maxLines, int minLines = 1}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.cover),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: AppText.gothic(11, weight: FontWeight.w600, color: AppColors.primary)),
          const Spacer(),
          Text('${c.text.characters.length}/$maxLength', style: AppText.grotesk(11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: (_) => setState(() {}),
          style: AppText.gothic(14, weight: FontWeight.w500, color: AppColors.textPrimary, height: 22 / 14),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            counterText: '',
            hintText: hint,
            hintStyle: AppText.gothic(14, color: AppColors.textSecondary, height: 22 / 14),
          ),
        ),
      ]),
    );
  }

  Widget _step(String label, String hint, int value, ValueChanged<int> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.gothic(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(hint, style: AppText.gothic(11, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == i ? AppColors.primary : AppColors.chip,
                  borderRadius: BorderRadius.circular(AppRadius.scoreButton),
                ),
                child: Text('$i',
                    style: AppText.grotesk(16, weight: FontWeight.w700, color: value == i ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ]),
    ]);
  }

  // ── 저장 버튼 ──────────────────────────────────────────

  Widget _saveBar() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.navBackground, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Opacity(
          opacity: _canSave || _saving ? 1 : 0.5,
          child: Material(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: _canSave ? _save : null,
              child: SizedBox(
                height: 50,
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink))
                      : Text(_editing ? '수정 완료' : '기록 남기기',
                          style: AppText.gothic(16, weight: FontWeight.w600, color: AppColors.ink)),
                ),
              ),
            ),
          ),
        ),
      );
}
