import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final String icon;
}

const _tabs = [
  _Tab('홈', 'assets/images/icon_home.svg'),
  _Tab('탐색', 'assets/images/icon_search.svg'),
  _Tab('기록', 'assets/images/icon_clock.svg'),
  _Tab('나', 'assets/images/icon_user.svg'),
];

/// 하단 플로팅 내비: 알약형, 선택된 탭은 lavender 알약 + 아이콘 + 글자,
/// 나머지는 아이콘만(투명도 65%).
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [BoxShadow(color: Color(0x33170A40), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _tabs.length; i++) _item(i),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final tab = _tabs[i];
    final selected = i == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Opacity(
          opacity: selected ? 1 : 0.65,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                tab.icon,
                width: 22,
                height: 22,
                // 선택된 탭은 어두운 아이콘, 나머지는 흰 아이콘
                colorFilter: ColorFilter.mode(selected ? AppColors.ink : Colors.white, BlendMode.srcIn),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(tab.label, style: AppText.gothic(13, weight: FontWeight.w800, color: AppColors.ink)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
