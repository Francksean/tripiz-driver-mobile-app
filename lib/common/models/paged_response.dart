class PagedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool last;
  final bool first;

  PagedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.first,
  });

  factory PagedResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PagedResponse<T>(
      content:
          (json['content'] as List).map((item) => fromJsonT(item)).toList(),
      pageNumber: json['pageable']['pageNumber'],
      pageSize: json['pageable']['pageSize'],
      totalPages: json['totalPages'],
      totalElements: json['totalElements'],
      last: json['last'],
      first: json['first'],
    );
  }
}
