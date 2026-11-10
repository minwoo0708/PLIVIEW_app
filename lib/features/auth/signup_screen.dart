import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/brand_chip.dart';
import '../../shared/widgets/primary_button.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// 12 회원가입
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nickname = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _nicknameError;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nickname.dispose();
    super.dispose();
  }

  bool get _lengthOk => _password.text.length >= 8 && _password.text.length <= 20;
  bool get _mixOk => RegExp(r'[A-Za-z]').hasMatch(_password.text) && RegExp(r'\d').hasMatch(_password.text);

  Future<void> _submit() async {
    final email = _email.text.trim();
    final nickname = _nickname.text.trim();
    setState(() {
      _emailError = !_emailPattern.hasMatch(email)
          ? '올바른 이메일 주소를 입력해 주세요.'
          : (email.length > 100 ? '이메일은 100자 이하로 입력해 주세요.' : null);
      _passwordError = (_lengthOk && _mixOk) ? null : '8~20자, 영문과 숫자를 모두 포함해 주세요.';
      _confirmError = _confirm.text == _password.text ? null : '비밀번호가 일치하지 않아요.';
      _nicknameError = (nickname.length < 2 || nickname.length > 20) ? '닉네임은 2~20자로 입력해 주세요.' : null;
      _formError = null;
    });
    if ([_emailError, _passwordError, _confirmError, _nicknameError].any((e) => e != null)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signup(
            email: email,
            password: _password.text,
            nickname: nickname,
          );
      // 가입 즉시 로그인되므로 라우터가 홈으로 보냅니다.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = e.code == 'EMAIL_ALREADY_EXISTS' ? '이미 가입된 이메일이에요.' : e.fieldErrors['email'];
        _passwordError = e.fieldErrors['password'];
        _nicknameError = e.fieldErrors['nickname'];
        final handled = e.code == 'EMAIL_ALREADY_EXISTS' || e.fieldErrors.isNotEmpty;
        _formError = handled ? null : e.userMessage;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkScaffold(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.start)),
            const SizedBox(height: 18),
            Text('회원가입', style: AppText.jua(30)),
            const SizedBox(height: 8),
            Text('이메일로 가입하고 바로 리뷰를 남겨요', style: AppText.gothic(14, color: AppColors.white75)),
            const SizedBox(height: 22),
            AppTextField(
              label: '이메일',
              hint: '이메일 주소',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: '비밀번호',
              hint: '8~20자, 영문+숫자',
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.next,
              errorText: _passwordError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _rule('8~20자', _lengthOk),
              const SizedBox(width: 14),
              _rule('영문+숫자', _mixOk),
            ]),
            const SizedBox(height: 14),
            AppTextField(
              label: '비밀번호 확인',
              hint: '비밀번호를 한 번 더 입력',
              controller: _confirm,
              obscure: true,
              textInputAction: TextInputAction.next,
              errorText: _confirmError,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: '닉네임',
              hint: '2~20자',
              controller: _nickname,
              textInputAction: TextInputAction.done,
              errorText: _nicknameError,
              onSubmitted: (_) => _submit(),
            ),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Text(_formError!, style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.error)),
              ),
            const SizedBox(height: 22),
            PrimaryButton(label: '가입하기', onPressed: _submit, loading: _loading),
          ],
        ),
      ),
    );
  }

  Widget _rule(String text, bool ok) => Text(
        '${ok ? '✓' : '○'} $text',
        style: AppText.mixed(
          12,
          weight: FontWeight.w600,
          color: ok ? AppColors.lavender : AppColors.white55,
        ),
      );
}
