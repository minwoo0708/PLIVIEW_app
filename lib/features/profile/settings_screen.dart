import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/user.dart';
import '../../core/router/app_router.dart';
import '../../core/spotify/spotify_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/brand_chip.dart';

/// 13 설정
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _changeNickname(BuildContext context, WidgetRef ref, User me) async {
    final result = await showDialog<String>(context: context, builder: (_) => _NicknameDialog(current: me.nickname));
    if (result == null || !context.mounted) return;
    try {
      final json = await ref.read(apiClientProvider).patch('/api/users/me', body: {'nickname': result});
      ref.read(authControllerProvider.notifier).updateUser(User.fromJson(json as Map<String, dynamic>));
      if (context.mounted) _toast(context, '닉네임을 바꿨어요.');
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.fieldErrors.values.firstOrNull ?? e.userMessage);
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String)>(context: context, builder: (_) => const _PasswordDialog());
    if (result == null || !context.mounted) return;
    try {
      await ref.read(apiClientProvider).patch('/api/users/me/password', body: {
        'currentPassword': result.$1,
        'newPassword': result.$2,
      });
      if (context.mounted) _toast(context, '비밀번호를 바꿨어요.');
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.fieldErrors.values.firstOrNull ?? e.userMessage);
    }
  }

  Future<void> _toggleSpotify(BuildContext context, WidgetRef ref, bool linked) async {
    final link = ref.read(spotifyLinkProvider.notifier);
    if (linked) {
      final ok = await _confirm(context, 'Spotify 연동을 해제할까요?', '재생 기록 탭은 다시 연동하기 전까지 볼 수 없어요.', '해제');
      if (ok == true) await link.disconnect();
      return;
    }
    try {
      final ok = await link.connect();
      if (context.mounted && ok) _toast(context, 'Spotify를 연동했어요.');
    } catch (_) {
      if (context.mounted) _toast(context, 'Spotify 연동에 실패했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, '로그아웃할까요?', '이 기기에서 로그아웃돼요.', '로그아웃');
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final password = await showDialog<String>(context: context, builder: (_) => const _WithdrawDialog());
    if (password == null || !context.mounted) return;
    try {
      await ref.read(apiClientProvider).delete('/api/users/me', body: {'password': password});
      await ref.read(authControllerProvider.notifier).logout();
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.userMessage);
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String body, String action) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title, style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
          content: Text(body, style: AppText.gothic(14, color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final spotifyLinked = ref.watch(spotifyLinkProvider).value ?? false;
    if (me == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(children: [
        // 위쪽 진한 띠
        Positioned(top: 0, left: 0, right: 0, height: 236 + MediaQuery.paddingOf(context).top - 44,
            child: const ColoredBox(color: AppColors.ink)),
        SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 24),
            children: [
              Row(children: [
                RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.me)),
                const SizedBox(width: 14),
                Text('설정', style: AppText.display(28)),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 24),
                child: Row(children: [
                  Avatar(nickname: me.nickname, imageUrl: me.profileImageUrl, size: 64),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(me.nickname, style: AppText.gothic(20, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(me.email ?? '', style: AppText.grotesk(13, color: AppColors.lavender)),
                  ]),
                ]),
              ),
              _label('계정'),
              _row('닉네임 변경', me.nickname, () => _changeNickname(context, ref, me)),
              const SizedBox(height: 10),
              _row('비밀번호 변경', '현재 비밀번호 확인 후 변경', () => _changePassword(context, ref)),
              const SizedBox(height: 18),
              _label('연동'),
              _row(
                'Spotify 연동',
                spotifyLinked ? '연동됨 (눌러서 해제하기)' : '내 재생 기록을 보려면 연동해 주세요',
                () => _toggleSpotify(context, ref, spotifyLinked),
              ),
              const SizedBox(height: 18),
              _label('기타'),
              _row('로그아웃', '이 기기에서 나가요', () => _logout(context, ref)),
              const SizedBox(height: 10),
              _row('회원 탈퇴', '내가 쓴 리뷰도 모두 삭제돼요', () => _withdraw(context, ref), danger: true),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppText.gothic(12, weight: FontWeight.w600, color: AppColors.textSecondary)),
      );

  Widget _row(String title, String sub, VoidCallback onTap, {bool danger = false}) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.cover)),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppText.gothic(15, weight: FontWeight.w600, color: danger ? const Color(0xFFD64545) : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.gothic(13, color: AppColors.textSecondary)),
              ]),
            ),
            SvgPicture.asset('assets/images/icon_chevron.svg', width: 20, height: 20),
          ]),
        ),
      );
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.current});

  final String current;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final _c = TextEditingController(text: widget.current);
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.length < 2 || v.length > 20) {
      setState(() => _error = '닉네임은 2~20자로 입력해 주세요.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('닉네임 변경', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
        content: TextField(
          controller: _c,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(hintText: '2~20자', errorText: _error),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: _submit, child: const Text('저장')),
        ],
      );
}

final _hasLetter = RegExp(r'[A-Za-z]');
final _hasDigit = RegExp(r'\d');

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  void _submit() {
    final n = _next.text;
    if (_current.text.isEmpty) {
      setState(() => _error = '현재 비밀번호를 입력해 주세요.');
    } else if (n.length < 8 || n.length > 20 || !_hasLetter.hasMatch(n) || !_hasDigit.hasMatch(n)) {
      setState(() => _error = '새 비밀번호는 8~20자, 영문과 숫자를 모두 포함해야 해요.');
    } else {
      Navigator.pop(context, (_current.text, n));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('비밀번호 변경', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _current, obscureText: true, decoration: const InputDecoration(hintText: '현재 비밀번호')),
          const SizedBox(height: 8),
          TextField(
            controller: _next,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: '새 비밀번호 (8~20자, 영문+숫자)', errorText: _error, errorMaxLines: 2),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: _submit, child: const Text('변경')),
        ],
      );
}

class _WithdrawDialog extends StatefulWidget {
  const _WithdrawDialog();

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_c.text.isEmpty) {
      setState(() => _error = '비밀번호를 입력해 주세요.');
      return;
    }
    Navigator.pop(context, _c.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('정말 탈퇴할까요?', style: AppText.gothic(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('내가 쓴 리뷰도 모두 삭제되고, 되돌릴 수 없어요.',
              style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            obscureText: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: '비밀번호 확인', errorText: _error),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: _submit,
            child: const Text('탈퇴하기', style: TextStyle(color: Color(0xFFD64545))),
          ),
        ],
      );
}
