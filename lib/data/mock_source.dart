import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class MockSource implements MediaSource {
  @override
  String get id => 'mock';

  final List<MediaItem> _items = const [
    MediaItem(
      id: 'mock:movie:1',
      title: 'Open Film Demo',
      overview: 'A demo movie item with downloadable sample stream.',
      posterUrl: 'https://picsum.photos/300/450?1',
      backdropUrl: 'https://picsum.photos/1200/500?1',
      mediaType: MediaType.movie,
      seasons: const [],
      variants: const [
        MediaVariant(
          id: 'v1',
          qualityLabel: '720p',
          bitrate: 1800,
          url: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        ),
      ],
      source: 'mock',
      releaseYear: '2026',
    ),
    MediaItem(
      id: 'mock:show:1',
      title: 'Demo Series',
      overview: 'A demo show with season and episodes.',
      posterUrl: 'https://picsum.photos/300/450?2',
      backdropUrl: 'https://picsum.photos/1200/500?2',
      mediaType: MediaType.show,
      seasons: const [
        Season(
          id: 's1',
          number: 1,
          title: 'Season 1',
          episodes: [
            Episode(
              id: 'e1',
              number: 1,
              title: 'Episode 1',
              durationSec: 1400,
              variants: [
                MediaVariant(
                  id: 'e1v1',
                  qualityLabel: '720p',
                  bitrate: 1800,
                  url: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                ),
              ],
            ),
            Episode(
              id: 'e2',
              number: 2,
              title: 'Episode 2',
              durationSec: 1400,
              variants: [
                MediaVariant(
                  id: 'e2v1',
                  qualityLabel: '720p',
                  bitrate: 1800,
                  url: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                ),
              ],
            ),
          ],
        ),
      ],
      variants: const [],
      source: 'mock',
      releaseYear: '2026',
    ),
  ];

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    return PagedResponse(items: _items, page: page, totalPages: 1);
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    return _items.firstWhere((e) => e.id == mediaId);
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final q = query.toLowerCase().trim();
    final filtered = _items
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.overview.toLowerCase().contains(q))
        .toList();
    return PagedResponse(items: filtered, page: page, totalPages: 1);
  }
}
