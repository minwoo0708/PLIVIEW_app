import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 아직 만들지 않은 탭 화면의 임시 자리. 화면이 완성되면 하나씩 교체합니다.
class TabPlaceholder extends ConsumerWidget {
  const TabPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.homeGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요, ${user?.nickname ?? ''}님', style: AppText.gothic(13, weight: FontWeight.w500, color: AppColors.white70)),
              Text(title, style: AppText.jua(30)),
            ],
          ),
        ),
      ),
    );
  }
}
