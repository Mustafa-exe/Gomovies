import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  Future<Directory> mediaRoot() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory('${dir.path}/media');
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<String> moviePath({required String title, required String extension}) async {
    final root = await mediaRoot();
    final folder = Directory('${root.path}/movies');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return '${folder.path}/${_safe(title)}.$extension';
  }

  Future<String> episodePath({
    required String show,
    required int season,
    required int episode,
    required String title,
    required String extension,
  }) async {
    final root = await mediaRoot();
    final folder = Directory(
      '${root.path}/shows/${_safe(show)}/season_${season.toString().padLeft(2, '0')}',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return '${folder.path}/s${season.toString().padLeft(2, '0')}e${episode.toString().padLeft(2, '0')}_${_safe(title)}.$extension';
  }

  String partialPath(String finalPath) => '$finalPath.part';
}
