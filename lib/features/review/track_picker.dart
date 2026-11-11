import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/music_repository.dart';
import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/cover_image.dart';

/// 하이라이트(최고의 곡 등)로 고를 곡을 선택하는 시트.
/// - 앨범: 수록곡 목록에서 고릅니다.
/// - 플리: 서버가 수록곡 목록을 주지 않아서, 곡을 검색해서 고릅니다.
Future<TrackRef?> pickTrack(BuildContext context, {required SpotifyItem item, required String title}) {
  return showModalBottomSheet<TrackRef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero))),
    builder: (_) => _TrackPickerSheet(item: item, title: title),
  );
}

class _TrackPickerSheet extends ConsumerStatefulWidget {
  const _TrackPickerSheet({required this.item, required this.title});

  final SpotifyItem item;
  final String title;

  @override
  ConsumerState<_TrackPickerSheet> createState() => _TrackPickerSheetState();
}

class _TrackPickerSheetState extends ConsumerState<_TrackPickerSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<SpotifyItem> _results = const [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  bool get _isAlbum => widget.item.kind == 'album';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text.trim()));
  }

  Future<void> _search(String q) async {
    final id = ++_requestId;
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(musicRepositoryProvider).search(q, 'track', limit: 10);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = page.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.userMessage;
        _loading = false;
      });
    }
  }

  void _select(SpotifyItem t) => Navigator.pop(context, TrackRef(spotifyId: t.id, name: t.name));

  @override
  Widget build(BuildContext context) {
    final tracks = _isAlbum ? widget.item.tracks : _results;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.title, style: AppText.display(20, color: AppColors.textPrimary)),
            ),
          ),
          if (!_isAlbum)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: AppText.gothic(14, color: AppColors.textPrimary),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: '플리에 있는 곡 이름을 검색해 주세요',
                    hintStyle: AppText.gothic(14, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SkeletonRows(count: 5, coverSize: 40))
                : _error != null
                    ? Center(child: Text(_error!, style: AppText.gothic(14, color: AppColors.textSecondary)))
                    : tracks.isEmpty
                        ? Center(
                            child: Text(_isAlbum ? '수록곡이 없어요' : '곡을 검색해 보세요',
                                style: AppText.gothic(14, color: AppColors.textSecondary)),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.paddingOf(context).bottom + 20),
                            itemCount: tracks.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = tracks[i];
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _select(t),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(AppRadius.scoreButton),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(children: [
                                    if (_isAlbum)
                                      SizedBox(
                                        width: 24,
                                        child: Text('${i + 1}',
                                            style: AppText.grotesk(13, weight: FontWeight.w500, color: AppColors.accent)),
                                      )
                                    else ...[
                                      CoverImage(url: t.imageUrl, size: 40, radius: 10, seed: t.id),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(t.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.mixed(14, weight: FontWeight.w800, color: AppColors.textPrimary)),
                                        if (!_isAlbum && t.subtitle != null)
                                          Text(t.subtitle!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.mixed(12, color: AppColors.textSecondary)),
                                      ]),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
          ),
        ]),
      ),
    );
  }
}
