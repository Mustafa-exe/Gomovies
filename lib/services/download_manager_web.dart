import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/models/download_task.dart';
import '../domain/models/media_item.dart';
import 'storage_service.dart';

class DownloadManager {
  DownloadManager({Dio? dio, StorageService? storage, this.maxConcurrent = 3});

  final int maxConcurrent;
  final StreamController<List<DownloadTask>> _controller =
      StreamController<List<DownloadTask>>.broadcast();

  Stream<List<DownloadTask>> get stream => _controller.stream;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('downloads_box')) {
      await Hive.openBox('downloads_box');
    }
    _controller.add(const <DownloadTask>[]);
  }

  void dispose() {
    _controller.close();
  }

  Future<String> queueMovie({
    required MediaItem item,
    required MediaVariant variant,
  }) {
    throw UnsupportedError('Downloads are not supported on web builds.');
  }

  Future<String> queueEpisode({
    required MediaItem item,
    required int seasonNumber,
    required Episode episode,
    required MediaVariant variant,
  }) {
    throw UnsupportedError('Downloads are not supported on web builds.');
  }

  Future<List<String>> queueSeason({
    required MediaItem item,
    required Season season,
    required String qualityLabel,
    List<MediaVariant> fallbackVariants = const [],
  }) {
    throw UnsupportedError('Downloads are not supported on web builds.');
  }

  void pause(String id) {}

  void resume(String id) {}

  Future<void> cancel(String id) async {}
}
