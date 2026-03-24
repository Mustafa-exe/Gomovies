import 'package:dio/dio.dart';

import '../core/config.dart';
import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class TmdbSource implements MediaSource {
  TmdbSource(this._dio);

  final Dio _dio;

  @override
  String get id => 'tmdb';

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    final res = await _dio.get(
      '${AppConfig.tmdbBaseUrl}/trending/all/week',
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'page': page,
      },
    );

    final data = Map<String, dynamic>.from(res.data as Map);
    final items = (data['results'] as List<dynamic>? ?? const [])
        .map((e) => _toMediaItem(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PagedResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? page,
    );
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final res = await _dio.get(
      '${AppConfig.tmdbBaseUrl}/search/multi',
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'query': query,
        'page': page,
      },
    );

    final data = Map<String, dynamic>.from(res.data as Map);
    final items = (data['results'] as List<dynamic>? ?? const [])
        .map((e) => _toMediaItem(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PagedResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? page,
    );
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    final split = mediaId.split(':');
    if (split.length != 2) {
      throw Exception('Invalid media id format.');
    }
    final type = split.first;
    final idNum = split.last;

    final res = await _dio.get(
      '${AppConfig.tmdbBaseUrl}/$type/$idNum',
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'append_to_response': 'videos',
      },
    );

    return _toMediaItem(Map<String, dynamic>.from(res.data as Map), forceType: type);
  }

  MediaItem _toMediaItem(Map<String, dynamic> data, {String? forceType}) {
    final typeRaw = forceType ?? data['media_type']?.toString() ?? 'movie';
    final isTv = typeRaw == 'tv';
    final idNum = data['id']?.toString() ?? '';
    final title = isTv
        ? (data['name']?.toString() ?? 'Untitled Show')
        : (data['title']?.toString() ?? 'Untitled Movie');

    final trailer = _extractTrailer(data);

    final variants = trailer == null
        ? const <MediaVariant>[]
        : [
            MediaVariant(
              id: 'trailer',
              qualityLabel: 'Trailer',
              bitrate: 0,
              url: trailer,
            ),
          ];

    return MediaItem(
      id: '$typeRaw:$idNum',
      title: title,
      overview: data['overview']?.toString() ?? '',
      posterUrl: _imageUrl(data['poster_path']?.toString()),
      backdropUrl: _imageUrl(data['backdrop_path']?.toString()),
      mediaType: isTv ? MediaType.show : MediaType.movie,
      seasons: const [],
      variants: variants,
      source: id,
      releaseYear: _year(
        isTv ? data['first_air_date']?.toString() : data['release_date']?.toString(),
      ),
    );
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${AppConfig.tmdbImageBaseUrl}$path';
  }

  String _year(String? value) {
    if (value == null || value.length < 4) return '';
    return value.substring(0, 4);
  }

  String? _extractTrailer(Map<String, dynamic> json) {
    final videos = json['videos'];
    if (videos is! Map) return null;
    final list = videos['results'];
    if (list is! List) return null;

    for (final dynamic raw in list) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString().toLowerCase();
      final site = raw['site']?.toString().toLowerCase();
      final key = raw['key']?.toString();
      if (type == 'trailer' && site == 'youtube' && key != null && key.isNotEmpty) {
        return 'https://www.youtube.com/watch?v=$key';
      }
    }

    return null;
  }
}
