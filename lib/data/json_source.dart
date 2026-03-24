import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import 'media_source.dart';

class JsonApiSource implements MediaSource {
  JsonApiSource({required this.sourceId, required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio();

  final String sourceId;
  final String baseUrl;
  final Dio _dio;

  @override
  String get id => sourceId;

  @override
  Future<PagedResponse> fetchCatalog({required int page}) async {
    final res = await _dio.get('$baseUrl/catalog?page=$page');
    final data = _asMap(res.data);
    return _toPaged(data, fallbackPage: page);
  }

  @override
  Future<PagedResponse> search({required String query, required int page}) async {
    final res = await _dio.get('$baseUrl/search?q=${Uri.encodeQueryComponent(query)}&page=$page');
    final data = _asMap(res.data);
    return _toPaged(data, fallbackPage: page);
  }

  @override
  Future<MediaItem> fetchDetails(String mediaId) async {
    final res = await _dio.get('$baseUrl/items/$mediaId');
    final data = _asMap(res.data);
    return MediaItem.fromJson(data);
  }

  PagedResponse _toPaged(Map<String, dynamic> data, {required int fallbackPage}) {
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PagedResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? fallbackPage,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? fallbackPage,
    );
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return Map<String, dynamic>.from(raw as Map);
  }
}
