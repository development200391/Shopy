class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) itemParser) {
    return PagedResult(
      items: (json['items'] as List).map((e) => itemParser(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
    );
  }
}
