import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// 프로필 사진(없으면 보라색 그라데이션 + 닉네임 첫 글자).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.nickname, this.imageUrl, this.size = 64, this.border = false});

  final String nickname;
  final String? imageUrl;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final initial = nickname.isEmpty ? '?' : nickname.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border ? Border.all(color: Colors.white, width: 3) : null,
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [Color(0xFFB395F9), AppColors.primary],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _initial(initial),
            )
          : _initial(initial),
    );
  }

  Widget _initial(String c) => Text(c, style: AppText.display(size * 0.4));
}
