class StorageService {
  Future<String> moviePath({required String title, required String extension}) {
    throw UnsupportedError('File-system paths are not supported on web builds.');
  }

  Future<String> episodePath({
    required String show,
    required int season,
    required int episode,
    required String title,
    required String extension,
  }) {
    throw UnsupportedError('File-system paths are not supported on web builds.');
  }

  String partialPath(String finalPath) => '$finalPath.part';
}
