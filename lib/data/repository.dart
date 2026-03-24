import 'package:collection/collection.dart';

import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'local_cache.dart';
import 'media_source.dart';

class MediaRepository {
  MediaRepository({required List<MediaSource> sources, required LocalCache cache})
      : _sources = sources,
        _cache = cache;

  final List<MediaSource> _sources;
  final LocalCache _cache;

  Future<void> init() => _cache.init();

  Future<PagedResponse> fetchCatalog({required int page}) async {
    await init();
    try {
      final resultSets = await _collectPages((s) => s.fetchCatalog(page: page));
      if (resultSets.isEmpty) {
        throw Exception('No sources returned catalog data.');
      }
      final merged = _merge(resultSets);
      await _cache.putCatalogPage('catalog:$page', merged.items);
      return merged;
    } catch (_) {
      final cached = _cache.getCatalogPage('catalog:$page');
      if (cached.isNotEmpty) {
        return PagedResponse(items: cached, page: page, totalPages: page);
      }
      rethrow;
    }
  }

  Future<PagedResponse> search({required String query, required int page}) async {
    await init();
    try {
      final resultSets = await _collectPages((s) => s.search(query: query, page: page));
      if (resultSets.isEmpty) {
        throw Exception('No sources returned search data.');
      }
      final merged = _merge(resultSets);
      await _cache.putCatalogPage('search:$query:$page', merged.items);
      return merged;
    } catch (_) {
      final cached = _cache.getCatalogPage('search:$query:$page');
      if (cached.isNotEmpty) {
        return PagedResponse(items: cached, page: page, totalPages: page);
      }
      rethrow;
    }
  }

  Future<MediaItem> details(String mediaId) async {
    await init();
    final cached = _cache.getDetails(mediaId);
    if (cached != null) return cached;

    for (final source in _sources) {
      try {
        final item = await source.fetchDetails(mediaId);
        final resolved = await _resolvePlayableDetails(item);
        await _cache.putDetails(resolved);
        return resolved;
      } catch (_) {
        continue;
      }
    }

    throw Exception('Unable to load details for $mediaId');
  }

  Future<MediaItem> _resolvePlayableDetails(MediaItem item) async {
    if (_hasPlayableContent(item)) {
      return item;
    }

    for (final source in _sources) {
      if (source.id == item.source) {
        continue;
      }

      try {
        final search = await source.search(query: item.title, page: 1);
        if (search.items.isEmpty) {
          continue;
        }

        final candidate = _bestCandidate(item, search.items);
        final details = await source.fetchDetails(candidate.id);
        if (!_hasPlayableContent(details)) {
          continue;
        }

        return MediaItem(
          id: item.id,
          title: item.title,
          overview: item.overview,
          posterUrl: item.posterUrl,
          backdropUrl: item.backdropUrl,
          mediaType: item.mediaType,
          seasons: item.seasons,
          variants: details.variants,
          source: item.source,
          releaseYear: item.releaseYear,
        );
      } catch (_) {
        continue;
      }
    }

    return item;
  }

  MediaItem _bestCandidate(MediaItem target, List<MediaItem> candidates) {
    final targetNorm = _normalize(target.title);

    int score(MediaItem item) {
      final titleNorm = _normalize(item.title);
      var value = 0;
      if (titleNorm == targetNorm) value += 1000;
      if (titleNorm.startsWith(targetNorm) || targetNorm.startsWith(titleNorm)) value += 200;
      if (titleNorm.contains(targetNorm) || targetNorm.contains(titleNorm)) value += 100;
      if (target.releaseYear.isNotEmpty && item.releaseYear == target.releaseYear) value += 25;
      if (item.mediaType == target.mediaType) value += 10;
      return value;
    }

    final ranked = [...candidates]..sort((a, b) => score(b).compareTo(score(a)));
    return ranked.first;
  }

  bool _hasPlayableContent(MediaItem item) {
    if (item.variants.isNotEmpty) {
      return true;
    }

    for (final season in item.seasons) {
      for (final episode in season.episodes) {
        if (episode.variants.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Future<List<PagedResponse>> _collectPages(
    Future<PagedResponse> Function(MediaSource source) loader,
  ) async {
    final values = <PagedResponse>[];
    for (final source in _sources) {
      try {
        values.add(await loader(source));
      } catch (_) {
        continue;
      }
    }
    return values;
  }

  PagedResponse _merge(List<PagedResponse> values) {
    final all = values.expand((e) => e.items).toList();
    final unique = all
        .groupListsBy((e) => '${e.source}|${e.id}')
        .values
        .map((e) => e.first)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final maxPage = values.map((e) => e.page).fold<int>(1, (a, b) => a > b ? a : b);
    final maxTotal = values.map((e) => e.totalPages).fold<int>(1, (a, b) => a > b ? a : b);

    return PagedResponse(items: unique, page: maxPage, totalPages: maxTotal);
  }
}
