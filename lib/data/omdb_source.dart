import 'package:dio/dio.dart';

import '../core/config.dart';
import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class OmdbSource implements MediaSource {
  OmdbSource(this._dio);

  final Dio _dio;

  @override
  String get id => 'omdb';

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    // OMDb has no generic discover endpoint. Use a broad trending-like query fallback.
    return search(query: 'popular', page: page);
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final q = query.trim();
    if (q.isEmpty) {
      return PagedResponse(items: const [], page: page, totalPages: 1);
    }

    final res = await _dio.get(
      AppConfig.omdbBaseUrl,
      queryParameters: {
        'apikey': AppConfig.omdbApiKey,
        's': q,
        'page': page,
      },
    );

    final data = Map<String, dynamic>.from(res.data as Map);
    if ((data['Response']?.toString() ?? 'False') != 'True') {
      return PagedResponse(items: const [], page: page, totalPages: 1);
    }

    final list = (data['Search'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(_toMediaItem)
        .toList();

    final totalResults = int.tryParse(data['totalResults']?.toString() ?? '') ?? list.length;
    final totalPages = (totalResults / 10).ceil().clamp(1, 1000);

    return PagedResponse(items: list, page: page, totalPages: totalPages);
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    if (!mediaId.startsWith('omdb:')) {
      throw Exception('Unsupported media id for OMDb: $mediaId');
    }

    final imdbId = mediaId.replaceFirst('omdb:', '');
    final res = await _dio.get(
      AppConfig.omdbBaseUrl,
      queryParameters: {
        'apikey': AppConfig.omdbApiKey,
        'i': imdbId,
        'plot': 'full',
      },
    );

    final data = Map<String, dynamic>.from(res.data as Map);
    if ((data['Response']?.toString() ?? 'False') != 'True') {
      throw Exception(data['Error']?.toString() ?? 'OMDb request failed');
    }

    return _toMediaItem(data);
  }

  MediaItem _toMediaItem(Map<String, dynamic> json) {
    final type = (json['Type']?.toString() ?? '').toLowerCase();
    final imdbId = json['imdbID']?.toString() ?? '';
    final year = json['Year']?.toString() ?? '';
    final poster = json['Poster']?.toString() ?? '';

    return MediaItem(
      id: 'omdb:$imdbId',
      title: json['Title']?.toString() ?? 'Untitled',
      overview: json['Plot']?.toString() == null || json['Plot'] == 'N/A'
          ? ''
          : json['Plot']!.toString(),
      posterUrl: poster == 'N/A' ? '' : poster,
      backdropUrl: poster == 'N/A' ? '' : poster,
      mediaType: type == 'series' ? MediaType.show : MediaType.movie,
      seasons: const [],
      variants: const [],
      source: id,
      releaseYear: year.length >= 4 ? year.substring(0, 4) : year,
    );
  }
}
