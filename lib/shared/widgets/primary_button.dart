import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// 기본 버튼: 높이 52, lavender 배경, ink 글자, 알약형.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.background = AppColors.lavender,
    this.foreground = AppColors.ink,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color background;
  final Color foreground;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[leading!, const SizedBox(width: 8)],
                        Text(label, style: AppText.gothic(16, weight: FontWeight.w800, color: foreground)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
