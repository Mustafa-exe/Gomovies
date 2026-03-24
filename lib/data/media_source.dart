import '../domain/models/paged_response.dart';
import '../domain/models/media_item.dart';

abstract class MediaSource {
  String get id;

  Future<PagedResponse> fetchCatalog({required int page});

  Future<PagedResponse> search({required String query, required int page});

  Future<MediaItem> fetchDetails(String mediaId);
}
