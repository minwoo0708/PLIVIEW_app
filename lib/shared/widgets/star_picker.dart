import 'package:flutter/material.dart';

import 'star_rating.dart';

/// 별 5개를 눌러 0.5 단위 점수를 고르는 위젯. 별의 왼쪽 절반을 누르면 반 별, 오른쪽 절반은 한 별.
class StarPicker extends StatelessWidget {
  const StarPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 22,
    this.gap = 4,
    this.dragToChange = false,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double size;
  final double gap;

  /// true면 별 위를 드래그하는 동안 계속 값이 바뀝니다(평가하기 화면). 목록에서는 오작동을 막으려고 끕니다.
  final bool dragToChange;

  double _fromDx(double dx) {
    final total = size * 5 + gap * 4;
    final x = dx.clamp(0.0, total - 0.01);
    final index = (x / (size + gap)).floor();
    final inStar = x - index * (size + gap);
    return inStar < size / 2 ? index + 0.5 : index + 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => onChanged(_fromDx(d.localPosition.dx)),
      onHorizontalDragUpdate: dragToChange ? (d) => onChanged(_fromDx(d.localPosition.dx)) : null,
      child: StarRating(value: value, size: size, gap: gap),
    );
  }
}
