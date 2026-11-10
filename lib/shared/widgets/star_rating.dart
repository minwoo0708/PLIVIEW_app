import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 별 5개로 점수(0.5 단위)를 보여 줍니다. 반 별은 빈 별 위에 절반만 채운 별을 겹쳐서 그립니다.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 16, this.gap = 2, this.fillColor});

  final double value;
  final double size;
  final double gap;

  /// 채워진 별 색(기본은 디자인의 보라색 SVG 그대로). 어두운 배경에서 바꿀 때 씁니다.
  final Color? fillColor;

  Widget _svg(String name) => SvgPicture.asset(
        'assets/images/$name',
        width: size,
        height: size,
        colorFilter: (fillColor != null && name != 'star_empty.svg')
            ? ColorFilter.mode(fillColor!, BlendMode.srcIn)
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) SizedBox(width: gap),
          if (value >= i + 1)
            _svg('star_full.svg')
          else if (value >= i + 0.5)
            SizedBox(
              width: size,
              height: size,
              child: Stack(children: [
                _svg('star_empty.svg'),
                ClipRect(clipper: _HalfClipper(), child: _svg('star_half_fill.svg')),
              ]),
            )
          else
            _svg('star_empty.svg'),
        ],
      ],
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
