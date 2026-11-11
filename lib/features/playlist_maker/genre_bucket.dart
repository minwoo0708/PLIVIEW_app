/// 취향 플리를 장르로 나눌 때 쓰는 큰 묶음. Spotify가 아티스트에 붙이는 세부 장르(예: "korean r&b")를
/// 아래 규칙으로 사용자가 이해하기 쉬운 묶음으로 바꿔요. 한 곡이 여러 묶음에 들어갈 수 있어요.
enum GenreBucket {
  hiphop('힙합'),
  ballad('발라드'),
  kpop('K-pop'),
  pop('팝'),
  rock('락'),
  other('기타');

  const GenreBucket(this.label);

  final String label;

  static Set<GenreBucket> fromGenres(List<String> genres) {
    final found = <GenreBucket>{};
    for (final raw in genres) {
      final g = raw.toLowerCase();
      if (_has(g, const ['hip hop', 'rap', 'trap', 'drill'])) found.add(hiphop);
      if (_has(g, const ['ballad', 'korean ost'])) found.add(ballad);
      if (_has(g, const ['k-pop', 'korean', 'k-rap', 'k-indie'])) found.add(kpop);
      if (g.contains('pop') && !g.contains('k-pop') && !g.contains('j-pop')) found.add(pop);
      if (_has(g, const ['rock', 'metal', 'punk', 'grunge', 'emo'])) found.add(rock);
    }
    return found.isEmpty ? {other} : found;
  }

  static bool _has(String g, List<String> words) => words.any(g.contains);
}
