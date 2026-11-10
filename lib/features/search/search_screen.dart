import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/item_tile.dart';

/// 03 탐색 (Spotify 검색)
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

const _kinds = [
  ('track', '곡', ItemType.track),
  ('album', '앨범', ItemType.album),
  ('artist', '아티스트', null),
  ('playlist', '플리', ItemType.playlist),
];

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _pageSize = 20;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  int _kindIndex = 0;
  String _query = '';
  List<SpotifyItem> _items = [];
  Map<String, Review> _mine = {};
  bool _loading = false;
  bool _hasNext = false;
  ApiException? _error;

  /// 오래된 응답이 최신 결과를 덮어쓰지 않게 요청마다 번호를 매깁니다.
  int _requestId = 0;

  String get _kind => _kinds[_kindIndex].$1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadMore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _startSearch(text.trim()));
  }

  void _selectKind(int i) {
    if (i == _kindIndex) return;
    setState(() => _kindIndex = i);
    _startSearch(_query);
  }

  Future<void> _startSearch(String q) async {
    final id = ++_requestId;
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _items = [];
        _hasNext = false;
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _query = q;
      _items = [];
      _mine = {};
      _hasNext = false;
      _loading = true;
      _error = null;
    });
    await _fetch(id, 0);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext || _query.isEmpty) return;
    final id = ++_requestId;
    setState(() => _loading = true);
    await _fetch(id, _items.length);
  }

  Future<void> _fetch(int id, int offset) async {
    final repo = ref.read(musicRepositoryProvider);
    final kind = _kind;
    try {
      final page = await repo.search(_query, kind, limit: _pageSize, offset: offset);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = [..._items, ...page.items];
        _hasNext = page.hasNext;
        _loading = false;
      });
      _loadMyRatings(id, kind, page.items);
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// 이미 평가한 항목에 별점 배지를 붙이려고 내 리뷰를 한꺼번에 조회합니다.
  Future<void> _loadMyRatings(int id, String kind, List<SpotifyItem> items) async {
    final type = _kinds.firstWhere((k) => k.$1 == kind).$3;
    if (type == null || items.isEmpty) return;
    try {
      final mine = await ref.read(musicRepositoryProvider).myReviews(type, items.map((e) => e.id).toList());
      if (!mounted || kind != _kind) return;
      setState(() => _mine = {..._mine, ...mine});
    } on ApiException {
      // 별점 배지는 덤이라 실패해도 조용히 넘어갑니다.
    }
  }

  void _open(SpotifyItem item) => context.push(Routes.item(item.kind, item.id));

  Future<void> _openLinkDialog() async {
    final id = await showDialog<String>(context: context, builder: (_) => const _PlaylistLinkDialog());
    if (id != null && mounted) context.push(Routes.item('playlist', id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ink, AppColors.inkMid, AppColors.surface, AppColors.surface],
          stops: [0, 0.24, 0.40, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('무엇을 찾고 있나요?', style: AppText.jua(24)),
                  const SizedBox(height: 14),
                  _searchBox(),
                  const SizedBox(height: 14),
                  _segmented(),
                  if (_kind == 'playlist') ...[
                    const SizedBox(height: 14),
                    _linkButton(),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 52,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.cover)),
        child: Row(children: [
          SvgPicture.asset('assets/images/icon_search_purple.svg', width: 20, height: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _debounce?.cancel();
                _startSearch(v.trim());
              },
              style: AppText.gothic(14, color: AppColors.textPrimary),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '아티스트, 앨범, 곡, 플리',
                hintStyle: AppText.gothic(14, color: AppColors.textSecondary),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                _startSearch('');
              },
              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
            ),
        ]),
      );

  Widget _segmented() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.white14, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(children: [
          for (var i = 0; i < _kinds.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectKind(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == _kindIndex ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _kinds[i].$2,
                    style: i == _kindIndex
                        ? AppText.gothic(13, weight: FontWeight.w800, color: AppColors.ink)
                        : AppText.gothic(13, weight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ),
            ),
        ]),
      );

  Widget _linkButton() => GestureDetector(
        onTap: _openLinkDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white8,
            borderRadius: BorderRadius.circular(AppRadius.scoreButton),
            border: Border.all(color: const Color(0xCCC9B8FF)),
          ),
          child: Row(children: [
            SvgPicture.asset('assets/images/icon_link.svg', width: 16, height: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('공유 링크로 플리 바로 불러오기', style: AppText.gothic(12, weight: FontWeight.w500)),
            ),
            SvgPicture.asset('assets/images/icon_arrow.svg', width: 16, height: 16),
          ]),
        ),
      );

  Widget _results() {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 110; // 플로팅 내비 높이만큼 비움
    if (_query.isEmpty) {
      return _message('곡, 앨범, 아티스트, 플리를 검색해 보세요');
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_items.isEmpty && _error != null) {
      return _message(_error!.userMessage, retry: () => _startSearch(_query));
    }
    if (_items.isEmpty) return _message('검색 결과가 없어요');

    final isTrack = _kind == 'track';
    final footer = _loading
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        : const SizedBox.shrink();

    if (isTrack) {
      return ListView.separated(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _items.length) return footer;
          final it = _items[i];
          return ItemRow(
            id: it.id,
            title: it.name,
            subtitle: it.subtitle,
            imageUrl: it.imageUrl,
            rating: _mine[it.id]?.rating,
            onTap: () => _open(it),
          );
        },
      );
    }

    final rows = (_items.length + 1) ~/ 2;
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
      itemCount: rows + 1,
      itemBuilder: (_, r) {
        if (r == rows) return footer;
        Widget tile(int i) {
          if (i >= _items.length) return const SizedBox.shrink();
          final it = _items[i];
          return ItemTile(
            id: it.id,
            title: it.name,
            subtitle: switch (it.kind) {
              'playlist' => it.subtitle,
              'album' => it.subtitle,
              _ => null,
            },
            imageUrl: it.imageUrl,
            rating: _mine[it.id]?.rating,
            onTap: () => _open(it),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(r * 2)),
              const SizedBox(width: 12),
              Expanded(child: tile(r * 2 + 1)),
            ],
          ),
        );
      },
    );
  }

  Widget _message(String text, {VoidCallback? retry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  textAlign: TextAlign.center, style: AppText.gothic(14, color: AppColors.textSecondary)),
              if (retry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: retry, child: const Text('다시 시도')),
              ],
            ],
          ),
        ),
      );
}

/// 공유 링크를 붙여 넣어 플리 id를 꺼냅니다.
class _PlaylistLinkDialog extends StatefulWidget {
  const _PlaylistLinkDialog();

  @override
  State<_PlaylistLinkDialog> createState() => _PlaylistLinkDialogState();
}

class _PlaylistLinkDialogState extends State<_PlaylistLinkDialog> {
  final _c = TextEditingController();
  String? _error;

  /// `https://open.spotify.com/playlist/{id}?si=...` 또는 `spotify:playlist:{id}`에서 id를 꺼냅니다.
  static String? parsePlaylistId(String text) {
    final m = RegExp(r'playlist[/:]([A-Za-z0-9]{1,64})').firstMatch(text.trim());
    return m?.group(1);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final id = parsePlaylistId(_c.text);
    if (id == null) {
      setState(() => _error = 'Spotify 플리 공유 링크가 아니에요.');
      return;
    }
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('공유 링크로 불러오기', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spotify에서 플리 → 공유 → 링크 복사 후 붙여 넣어 주세요.',
              style: AppText.gothic(13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'https://open.spotify.com/playlist/...',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(onPressed: _submit, child: const Text('불러오기')),
      ],
    );
  }
}
