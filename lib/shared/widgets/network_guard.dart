import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// 인터넷 연결이 없으면 안내 창을 띄우고, 확인을 누르면 앱을 종료합니다.
/// 앱을 켤 때와 쓰는 중에 연결이 끊길 때 모두 감시해요.
class NetworkGuard extends StatefulWidget {
  const NetworkGuard({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkGuard> createState() => _NetworkGuardState();
}

class _NetworkGuardState extends State<NetworkGuard> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update);
    _sub = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_offline) ...[
        const ModalBarrier(color: Color(0x99000000), dismissible: false),
        Center(
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.accent),
                const SizedBox(height: 14),
                Text('네트워크에 연결할 수 없어요',
                    textAlign: TextAlign.center,
                    style: AppText.mixed(17, weight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('인터넷 연결을 확인한 뒤 앱을 다시 실행해 주세요.',
                    textAlign: TextAlign.center,
                    style: AppText.gothic(14, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () => SystemNavigator.pop(),
                    child: Text('앱 종료', style: AppText.gothic(15, weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }
}
