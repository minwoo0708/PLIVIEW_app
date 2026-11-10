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

/// 11 로그인
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty ? '이메일을 입력해 주세요.' : null;
      _passwordError = password.isEmpty ? '비밀번호를 입력해 주세요.' : null;
      _formError = null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(email: email, password: password);
      // 성공하면 라우터가 알아서 홈으로 보냅니다.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = e.fieldErrors['email'];
        _passwordError = e.fieldErrors['password'];
        _formError = e.fieldErrors.isEmpty ? e.userMessage : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandChip(),
                    const SizedBox(height: 14),
                    Text('다시 만나서\n반가워요', style: AppText.display(34)),
                    const SizedBox(height: 14),
                    Text('듣고 남긴 점수를 이어서 기록해요', style: AppText.gothic(14, color: AppColors.white75)),
                    const SizedBox(height: 28),
                    AppTextField(
                      label: '이메일',
                      hint: '이메일 주소',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: '비밀번호',
                      hint: '비밀번호',
                      controller: _password,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: _passwordError,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_formError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 4),
                        child: Text(_formError!, style: AppText.gothic(13, weight: FontWeight.w600, color: AppColors.error)),
                      ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: '로그인', onPressed: _submit, loading: _loading),
                    const Spacer(),
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go(Routes.signup),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text.rich(TextSpan(
                            style: AppText.gothic(14, color: AppColors.white75),
                            children: [
                              const TextSpan(text: '아직 계정이 없나요? '),
                              TextSpan(
                                text: '회원가입',
                                style: AppText.gothic(14, weight: FontWeight.w800, color: AppColors.lavender),
                              ),
                            ],
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
