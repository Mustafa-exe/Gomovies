import 'package:dio/dio.dart';

import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class TvMazeSource implements MediaSource {
  TvMazeSource(this._dio);

  final Dio _dio;

  @override
  String get id => 'tvmaze';

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    // TVMaze uses 0-based page indexing.
    final res = await _dio.get(
      'https://api.tvmaze.com/shows',
      queryParameters: {'page': (page - 1).clamp(0, 9999)},
    );

    final rows = (res.data as List<dynamic>? ?? const []);
    final items = rows
        .map((e) => _toMediaItem(Map<String, dynamic>.from(e as Map)))
        .where((e) => e.title.trim().isNotEmpty)
        .toList();

    // TVMaze does not provide total pages. Use optimistic value for infinite scroll.
    return PagedResponse(items: items, page: page, totalPages: page + 1);
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final q = query.trim();
    if (q.isEmpty) {
      return PagedResponse(items: const [], page: page, totalPages: 1);
    }

    // API has no page parameter for search; emulate paging client-side.
    final res = await _dio.get(
      'https://api.tvmaze.com/search/shows',
      queryParameters: {'q': q},
    );

    final rows = (res.data as List<dynamic>? ?? const []);
    final allItems = rows
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) => Map<String, dynamic>.from(e['show'] as Map? ?? const {}))
        .map(_toMediaItem)
        .where((e) => e.title.trim().isNotEmpty)
        .toList();

    const pageSize = 20;
    final start = (page - 1) * pageSize;
    if (start >= allItems.length) {
      return PagedResponse(
        items: const [],
        page: page,
        totalPages: (allItems.length / pageSize).ceil().clamp(1, 10000),
      );
    }

    final end = (start + pageSize).clamp(0, allItems.length);
    return PagedResponse(
      items: allItems.sublist(start, end),
      page: page,
      totalPages: (allItems.length / pageSize).ceil().clamp(1, 10000),
    );
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    if (!mediaId.startsWith('tvmaze:')) {
      throw Exception('Unsupported media id for TVMaze: $mediaId');
    }

    final idNum = mediaId.replaceFirst('tvmaze:', '');
    final showRes = await _dio.get('https://api.tvmaze.com/shows/$idNum');
    final episodesRes = await _dio.get('https://api.tvmaze.com/shows/$idNum/episodes');

    final showJson = Map<String, dynamic>.from(showRes.data as Map);
    final episodes = (episodesRes.data as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final ep in episodes) {
      final seasonNum = (ep['season'] as num?)?.toInt() ?? 1;
      grouped.putIfAbsent(seasonNum, () => []).add(ep);
    }

    final seasons = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _toMediaItem(
      showJson,
      seasonsOverride: seasons
          .map(
            (entry) => Season(
              id: 'tvmaze:$idNum:s${entry.key}',
              number: entry.key,
              title: 'Season ${entry.key}',
              episodes: entry.value
                  .map(
                    (ep) => Episode(
                      id: 'tvmaze:${ep['id']}',
                      number: (ep['number'] as num?)?.toInt() ?? 0,
                      title: ep['name']?.toString() ?? 'Episode',
                      durationSec: (((ep['runtime'] as num?)?.toInt() ?? 0) * 60),
                      variants: const [],
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.number.compareTo(b.number)),
            ),
          )
          .toList(),
    );
  }

  MediaItem _toMediaItem(
    Map<String, dynamic> json, {
    List<Season>? seasonsOverride,
  }) {
    final premiered = json['premiered']?.toString() ?? '';
    final image = Map<String, dynamic>.from(json['image'] as Map? ?? const {});
    final summaryRaw = json['summary']?.toString() ?? '';
    final summary = summaryRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    return MediaItem(
      id: 'tvmaze:${json['id']}',
      title: json['name']?.toString() ?? 'Untitled Show',
      overview: summary,
      posterUrl: image['medium']?.toString() ?? '',
      backdropUrl: image['original']?.toString() ?? image['medium']?.toString() ?? '',
      mediaType: MediaType.show,
      seasons: seasonsOverride ?? const [],
      variants: const [],
      source: id,
      releaseYear: premiered.length >= 4 ? premiered.substring(0, 4) : '',
    );
  }
}
