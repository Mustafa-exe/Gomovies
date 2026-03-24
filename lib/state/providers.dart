import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../data/internet_archive_source.dart';
import '../data/local_cache.dart';
import '../data/media_source.dart';
import '../data/mock_source.dart';
import '../data/omdb_source.dart';
import '../data/repository.dart';
import '../data/tmdb_source.dart';
import '../data/tvmaze_source.dart';
import '../domain/models/download_task.dart';
import '../domain/models/media_item.dart';
import '../domain/models/paged_response.dart';
import '../services/download_manager.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final cacheProvider = Provider<LocalCache>((ref) => LocalCache());

final sourcesProvider = Provider<List<MediaSource>>((ref) {
  final dio = ref.watch(dioProvider);

  final sources = <MediaSource>[
    TvMazeSource(dio),
    InternetArchiveSource(dio),
  ];

  if (AppConfig.tmdbApiKey.isNotEmpty) {
    sources.add(TmdbSource(dio));
  }

  if (AppConfig.omdbApiKey.isNotEmpty) {
    sources.add(OmdbSource(dio));
  }

  // Keep mock as fallback when APIs fail or for offline demonstration.
  sources.add(MockSource());

  // Add more JSON-based providers here to search across any medium/source.
  // Example:
  // sources.add(JsonApiSource(sourceId: 'custom', baseUrl: 'https://your-source.example/api'));

  return sources;
});

final repositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(
    sources: ref.watch(sourcesProvider),
    cache: ref.watch(cacheProvider),
  );
});

final catalogProvider = FutureProvider.family<PagedResponse, int>((ref, page) async {
  final repo = ref.watch(repositoryProvider);
  return repo.fetchCatalog(page: page);
});

final searchProvider =
    FutureProvider.family<PagedResponse, ({String query, int page})>((ref, args) async {
  final repo = ref.watch(repositoryProvider);
  return repo.search(query: args.query, page: args.page);
});

final detailsProvider = FutureProvider.family<MediaItem, String>((ref, mediaId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.details(mediaId);
});

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(dio: ref.watch(dioProvider));
  manager.init();
  ref.onDispose(manager.dispose);
  return manager;
});

final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  return ref.watch(downloadManagerProvider).stream;
});
