import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 피그마 디자인의 화면 배경: 화면 전체 높이에 걸친 진남색 → 보라(50%) → 연보라(92%) 그라데이션.
/// 위에 아주 옅은 노이즈를 한 겹 얹어서, 어두운 색에서 생기는 계단 모양 띠(밴딩)를 흐려 줍니다.
/// 배경은 화면에 고정되고, 내용([child])이 그 위에서 스크롤돼요.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.screenGradient))),
      const Positioned.fill(child: IgnorePointer(child: _NoiseOverlay())),
      Positioned.fill(child: child),
    ]);
  }
}

/// 128x128 무작위 회색 점 타일(투명도 약 4%)을 화면 전체에 반복해서 깔아요. 한 번만 만들어 재사용합니다.
class _NoiseOverlay extends StatefulWidget {
  const _NoiseOverlay();

  static Future<ui.Image>? _cache;

  static Future<ui.Image> load() => _cache ??= _make();

  static Future<ui.Image> _make() async {
    const size = 128;
    final rnd = Random(7);
    final bytes = Uint8List(size * size * 4);
    // 투명도가 곱해진(premultiplied) 값이어야 해요. 절반은 아주 옅은 흰 점, 절반은 아주 옅은 검은 점.
    const alpha = 7;
    for (var i = 0; i < size * size; i++) {
      final white = rnd.nextBool();
      final v = white ? alpha : 0;
      bytes[i * 4] = v;
      bytes[i * 4 + 1] = v;
      bytes[i * 4 + 2] = v;
      bytes[i * 4 + 3] = alpha;
    }
    return _decode(bytes, size);
  }

  static Future<ui.Image> _decode(Uint8List bytes, int size) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(bytes, size, size, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  @override
  State<_NoiseOverlay> createState() => _NoiseOverlayState();
}

class _NoiseOverlayState extends State<_NoiseOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _NoiseOverlay.load().then((img) {
      if (mounted) setState(() => _image = img);
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const SizedBox.shrink();
    return CustomPaint(painter: _NoisePainter(img), size: Size.infinite);
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _NoisePainter old) => old.image != image;
}

/// 배경 위 글자 색을 자리에 따라 바꿔 줘요. 피그마도 같은 방식이에요:
/// 화면 위쪽(진한 보라 배경)에서는 흰색, 아래쪽(연한 배경)에서는 어두운색.
/// 스크롤해서 글자가 아래로 내려가면 색이 부드럽게 바뀝니다.
class AdaptiveColor extends StatefulWidget {
  const AdaptiveColor({super.key, required this.onDark, required this.onLight, required this.builder});

  final Color onDark;
  final Color onLight;
  final Widget Function(BuildContext context, Color color) builder;

  @override
  State<AdaptiveColor> createState() => _AdaptiveColorState();
}

class _AdaptiveColorState extends State<AdaptiveColor> {
  ScrollPosition? _position;
  double _t = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(_update);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_update);
  }

  @override
  void dispose() {
    _position?.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.sizeOf(context).height;
    // 화면 높이의 55%까지는 흰색, 62% 아래로는 어두운색, 그 사이는 섞어요.
    final t = ((y / h - 0.55) / 0.07).clamp(0.0, 1.0);
    if ((t - _t).abs() > 0.02) setState(() => _t = t);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    return widget.builder(context, Color.lerp(widget.onDark, widget.onLight, _t)!);
  }
}
