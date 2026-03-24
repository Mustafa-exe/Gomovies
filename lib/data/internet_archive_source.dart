import 'package:dio/dio.dart';

import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class InternetArchiveSource implements MediaSource {
  InternetArchiveSource(this._dio);

  final Dio _dio;

  @override
  String get id => 'archive';

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    final data = await _advancedSearch(
      query: 'mediatype:(movies OR tv) AND -collection:(opensource_movies)',
      page: page,
    );

    return _mapSearchResponse(data, page);
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final q = query.trim();
    if (q.isEmpty) {
      return PagedResponse(items: const [], page: page, totalPages: 1);
    }

    final safeQuery = q.replaceAll('"', '');
    final data = await _advancedSearch(
      query: '(title:($safeQuery) OR subject:($safeQuery)) AND mediatype:(movies OR tv)',
      page: page,
    );

    return _mapSearchResponse(data, page);
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    if (!mediaId.startsWith('archive:')) {
      throw Exception('Unsupported media id for Internet Archive: $mediaId');
    }

    final identifier = mediaId.replaceFirst('archive:', '');
    final res = await _dio.get('https://archive.org/metadata/$identifier');
    final json = Map<String, dynamic>.from(res.data as Map);

    final meta = Map<String, dynamic>.from(json['metadata'] as Map? ?? const {});
    final files = (json['files'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final variants = files
        .where((f) {
          final name = f['name']?.toString().toLowerCase() ?? '';
          return name.endsWith('.mp4') || name.endsWith('.m4v') || name.endsWith('.webm') || name.endsWith('.ogv');
        })
        .map((f) {
          final name = f['name']?.toString() ?? '';
          final sizeBytes = int.tryParse(f['size']?.toString() ?? '') ?? 0;
          final bitrate = sizeBytes <= 0 ? 0 : (sizeBytes ~/ 125000);
          return MediaVariant(
            id: '$identifier:$name',
            qualityLabel: _guessQualityLabel(name),
            bitrate: bitrate,
            url: 'https://archive.org/download/$identifier/$name',
          );
        })
        .toList();

    final title = _firstString(meta['title']) ?? identifier;
    final description = _firstString(meta['description']) ?? '';
    final yearRaw = _firstString(meta['year']) ?? _firstString(meta['date']) ?? '';
    final year = yearRaw.length >= 4 ? yearRaw.substring(0, 4) : '';

    return MediaItem(
      id: mediaId,
      title: title,
      overview: _stripHtml(description),
      posterUrl: 'https://archive.org/services/img/$identifier',
      backdropUrl: 'https://archive.org/services/img/$identifier',
      mediaType: MediaType.movie,
      seasons: const [],
      variants: variants,
      source: id,
      releaseYear: year,
    );
  }

  Future<Map<String, dynamic>> _advancedSearch({required String query, required int page}) async {
    final res = await _dio.get(
      'https://archive.org/advancedsearch.php',
      queryParameters: {
        'q': query,
        'fl[]': ['identifier', 'title', 'description', 'year', 'date', 'mediatype'],
        'rows': 30,
        'page': page,
        'output': 'json',
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  PagedResponse _mapSearchResponse(Map<String, dynamic> data, int fallbackPage) {
    final resp = Map<String, dynamic>.from(data['response'] as Map? ?? const {});
    final docs = (resp['docs'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final items = docs
        .map((d) {
          final identifier = d['identifier']?.toString() ?? '';
          if (identifier.isEmpty) {
            return null;
          }
          final title = d['title']?.toString() ?? identifier;
          final desc = d['description']?.toString() ?? '';
          final yearRaw = d['year']?.toString() ?? d['date']?.toString() ?? '';
          final year = yearRaw.length >= 4 ? yearRaw.substring(0, 4) : '';
          return MediaItem(
            id: 'archive:$identifier',
            title: title,
            overview: _stripHtml(desc),
            posterUrl: 'https://archive.org/services/img/$identifier',
            backdropUrl: 'https://archive.org/services/img/$identifier',
            mediaType: MediaType.movie,
            seasons: const [],
            variants: const [],
            source: id,
            releaseYear: year,
          );
        })
        .whereType<MediaItem>()
        .toList();

    final start = (resp['start'] as num?)?.toInt() ?? 0;
    final numFound = (resp['numFound'] as num?)?.toInt() ?? items.length;
    final rows = (resp['docs'] as List<dynamic>? ?? const []).length;
    final page = rows > 0 ? (start ~/ rows) + 1 : fallbackPage;
    final totalPages = rows > 0 ? (numFound / rows).ceil().clamp(1, 100000) : page;

    return PagedResponse(items: items, page: page, totalPages: totalPages);
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _firstString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String) return first;
    }
    return value.toString();
  }

  String _guessQualityLabel(String fileName) {
    final name = fileName.toLowerCase();
    if (name.contains('2160') || name.contains('4k')) return '2160p';
    if (name.contains('1080')) return '1080p';
    if (name.contains('720')) return '720p';
    if (name.contains('480')) return '480p';
    return 'Auto';
  }
}
