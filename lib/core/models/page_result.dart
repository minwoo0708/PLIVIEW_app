/// 서버 페이지 응답 `{content, page, size, totalElements, totalPages, hasNext}`.
class PageResult<T> {
  const PageResult({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.hasNext,
  });

  final List<T> content;
  final int page;
  final int totalElements;
  final bool hasNext;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) =>
      PageResult(
        content: (json['content'] as List? ?? const [])
            .map((e) => fromItem(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] as bool? ?? false,
      );
}
