import 'media_item.dart';

class PagedResponse {
  const PagedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<MediaItem> items;
  final int page;
  final int totalPages;
}
