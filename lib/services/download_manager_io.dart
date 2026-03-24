import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/download_task.dart';
import '../domain/models/media_item.dart';
import 'storage_service.dart';

class DownloadManager {
  DownloadManager({Dio? dio, StorageService? storage, this.maxConcurrent = 3})
      : _dio = dio ?? Dio(),
        _storage = storage ?? StorageService();

  final Dio _dio;
  final StorageService _storage;
  final int maxConcurrent;

  final Queue<String> _queue = Queue<String>();
  final Map<String, DownloadTask> _tasks = <String, DownloadTask>{};
  final Map<String, CancelToken> _runningTokens = <String, CancelToken>{};
  final Set<String> _pauseRequested = <String>{};

  final StreamController<List<DownloadTask>> _controller =
      StreamController<List<DownloadTask>>.broadcast();

  Stream<List<DownloadTask>> get stream => _controller.stream;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('downloads_box')) {
      await Hive.openBox('downloads_box');
    }
    final box = Hive.box('downloads_box');
    for (final dynamic val in box.values) {
      if (val is Map) {
        final task = DownloadTask.fromJson(Map<String, dynamic>.from(val));
        _tasks[task.id] = task;
      }
    }
    _emit();
  }

  void dispose() {
    for (final token in _runningTokens.values) {
      token.cancel('manager_dispose');
    }
    _controller.close();
  }

  Future<String> queueMovie({
    required MediaItem item,
    required MediaVariant variant,
  }) async {
    final path = await _storage.moviePath(title: item.title, extension: _ext(variant.url));
    return _queueTask(
      itemId: item.id,
      title: item.title,
      season: null,
      episode: null,
      label: variant.qualityLabel,
      url: variant.url,
      finalPath: path,
    );
  }

  Future<String> queueEpisode({
    required MediaItem item,
    required int seasonNumber,
    required Episode episode,
    required MediaVariant variant,
  }) async {
    final path = await _storage.episodePath(
      show: item.title,
      season: seasonNumber,
      episode: episode.number,
      title: episode.title,
      extension: _ext(variant.url),
    );

    return _queueTask(
      itemId: item.id,
      title: item.title,
      season: seasonNumber,
      episode: episode.number,
      label: '${episode.title} (${variant.qualityLabel})',
      url: variant.url,
      finalPath: path,
    );
  }

  Future<List<String>> queueSeason({
    required MediaItem item,
    required Season season,
    required String qualityLabel,
    List<MediaVariant> fallbackVariants = const [],
  }) async {
    final ids = <String>[];
    for (final ep in season.episodes) {
      final variants = ep.variants.isNotEmpty ? ep.variants : fallbackVariants;
      if (variants.isEmpty) {
        continue;
      }
      final variant = variants.firstWhere(
        (v) => v.qualityLabel == qualityLabel,
        orElse: () => variants.first,
      );
      ids.add(await queueEpisode(
        item: item,
        seasonNumber: season.number,
        episode: ep,
        variant: variant,
      ));
    }
    return ids;
  }

  Future<String> _queueTask({
    required String itemId,
    required String title,
    required int? season,
    required int? episode,
    required String label,
    required String url,
    required String finalPath,
  }) async {
    final id = const Uuid().v4();
    final task = DownloadTask(
      id: id,
      itemId: itemId,
      itemTitle: title,
      seasonNumber: season,
      episodeNumber: episode,
      label: label,
      url: url,
      finalPath: finalPath,
      tempPath: _storage.partialPath(finalPath),
      status: DownloadStatus.queued,
      receivedBytes: 0,
      totalBytes: 0,
      createdAt: DateTime.now(),
    );
    _tasks[id] = task;
    _queue.add(id);
    await _persist(task);
    _emit();
    _pump();
    return id;
  }

  void pause(String id) {
    _pauseRequested.add(id);
    _runningTokens[id]?.cancel('pause');
  }

  void resume(String id) {
    final current = _tasks[id];
    if (current == null) return;
    if (current.status != DownloadStatus.paused && current.status != DownloadStatus.failed) {
      return;
    }
    _pauseRequested.remove(id);
    final next = current.copyWith(status: DownloadStatus.queued, error: null);
    _tasks[id] = next;
    _queue.add(id);
    _persist(next);
    _emit();
    _pump();
  }

  Future<void> cancel(String id) async {
    _runningTokens[id]?.cancel('cancel');
    _queue.remove(id);

    final current = _tasks[id];
    if (current == null) return;

    final part = File(current.tempPath);
    if (await part.exists()) {
      await part.delete();
    }

    final next = current.copyWith(status: DownloadStatus.canceled);
    _tasks[id] = next;
    await _persist(next);
    _emit();
  }

  void _pump() {
    while (_runningTokens.length < maxConcurrent && _queue.isNotEmpty) {
      final id = _queue.removeFirst();
      if (!_tasks.containsKey(id)) continue;
      _run(id);
    }
  }

  Future<void> _run(String id) async {
    final current = _tasks[id];
    if (current == null) return;

    final token = CancelToken();
    _runningTokens[id] = token;

    int existing = 0;
    try {
      final tempFile = File(current.tempPath);
      if (!await tempFile.exists()) {
        await tempFile.create(recursive: true);
      }
      existing = await tempFile.length();

      final started = current.copyWith(
        status: DownloadStatus.downloading,
        receivedBytes: existing,
      );
      _tasks[id] = started;
      await _persist(started);
      _emit();

      final response = await _dio.get<ResponseBody>(
        current.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: existing > 0 ? {'Range': 'bytes=$existing-'} : null,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
        cancelToken: token,
      );

      final len = int.tryParse(response.headers.value(HttpHeaders.contentLengthHeader) ?? '0') ?? 0;
      final total = len > 0 ? existing + len : 0;

      final raf = tempFile.openSync(mode: FileMode.append);
      await for (final chunk in response.data!.stream) {
        if (token.isCancelled) break;
        raf.writeFromSync(chunk);
        existing += chunk.length;
        final updating = _tasks[id];
        if (updating != null) {
          final next = updating.copyWith(
            status: DownloadStatus.downloading,
            receivedBytes: existing,
            totalBytes: total,
          );
          _tasks[id] = next;
          await _persist(next);
          _emit();
        }
      }
      raf.closeSync();

      if (token.isCancelled) {
        final paused = _pauseRequested.contains(id);
        final updating = _tasks[id];
        if (updating != null) {
          final next = updating.copyWith(
            status: paused ? DownloadStatus.paused : DownloadStatus.canceled,
          );
          _tasks[id] = next;
          await _persist(next);
          _emit();
        }
        return;
      }

      final output = File(current.finalPath);
      if (await output.exists()) {
        await output.delete();
      }
      await tempFile.rename(current.finalPath);

      final done = _tasks[id]?.copyWith(
        status: DownloadStatus.completed,
        receivedBytes: existing,
        totalBytes: total > 0 ? total : existing,
      );
      if (done != null) {
        _tasks[id] = done;
        await _persist(done);
        _emit();
      }
    } on DioException catch (e) {
      final paused = _pauseRequested.contains(id);
      final updating = _tasks[id];
      if (updating != null) {
        final failed = updating.copyWith(
          status: paused ? DownloadStatus.paused : DownloadStatus.failed,
          error: paused ? null : (e.message ?? 'Network error'),
        );
        _tasks[id] = failed;
        await _persist(failed);
        _emit();
      }
    } catch (e) {
      final updating = _tasks[id];
      if (updating != null) {
        final failed = updating.copyWith(
          status: DownloadStatus.failed,
          error: e.toString(),
        );
        _tasks[id] = failed;
        await _persist(failed);
        _emit();
      }
    } finally {
      _runningTokens.remove(id);
      _pump();
    }
  }

  Future<void> _persist(DownloadTask task) async {
    final box = Hive.box('downloads_box');
    await box.put(task.id, task.toJson());
  }

  String _ext(String url) {
    final uri = Uri.tryParse(url);
    final seg = uri?.pathSegments;
    if (seg == null || seg.isEmpty) return 'mp4';
    final last = seg.last;
    if (!last.contains('.')) return 'mp4';
    return last.split('.').last.toLowerCase();
  }

  void _emit() {
    final tasks = _tasks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(tasks);
  }
}
