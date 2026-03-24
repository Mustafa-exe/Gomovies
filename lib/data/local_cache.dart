import 'package:hive_flutter/hive_flutter.dart';

import '../domain/models/media_item.dart';

class LocalCache {
  static const String catalogBox = 'catalog_box';
  static const String detailsBox = 'details_box';
  static const String downloadsBox = 'downloads_box';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(catalogBox);
    await Hive.openBox(detailsBox);
    await Hive.openBox(downloadsBox);
    _initialized = true;
  }

  Future<void> putCatalogPage(String key, List<MediaItem> items) async {
    final box = Hive.box(catalogBox);
    await box.put(key, items.map((e) => e.toJson()).toList());
  }

  List<MediaItem> getCatalogPage(String key) {
    final box = Hive.box(catalogBox);
    final raw = box.get(key);
    if (raw is! List) return const [];

    return raw
        .map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> putDetails(MediaItem item) async {
    final box = Hive.box(detailsBox);
    await box.put(item.id, item.toJson());
  }

  MediaItem? getDetails(String id) {
    final box = Hive.box(detailsBox);
    final raw = box.get(id);
    if (raw is! Map) return null;
    return MediaItem.fromJson(Map<String, dynamic>.from(raw));
  }
}
