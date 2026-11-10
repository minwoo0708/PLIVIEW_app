import '../../core/models/review.dart';
import '../../core/models/spotify_item.dart';

/// 평가하기 화면으로 넘기는 값. [existing]이 있으면 수정 모드입니다.
class RateArgs {
  const RateArgs({required this.item, this.existing});

  final SpotifyItem item;
  final Review? existing;
}
