enum DownloadStatus { queued, downloading, paused, completed, failed, canceled }

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.label,
    required this.url,
    required this.finalPath,
    required this.tempPath,
    required this.status,
    required this.receivedBytes,
    required this.totalBytes,
    required this.createdAt,
    this.error,
  });

  final String id;
  final String itemId;
  final String itemTitle;
  final int? seasonNumber;
  final int? episodeNumber;
  final String label;
  final String url;
  final String finalPath;
  final String tempPath;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final DateTime createdAt;
  final String? error;

  double get progress => totalBytes <= 0 ? 0 : receivedBytes / totalBytes;

  DownloadTask copyWith({
    DownloadStatus? status,
    int? receivedBytes,
    int? totalBytes,
    String? error,
  }) {
    return DownloadTask(
      id: id,
      itemId: itemId,
      itemTitle: itemTitle,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      label: label,
      url: url,
      finalPath: finalPath,
      tempPath: tempPath,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt,
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'label': label,
        'url': url,
        'finalPath': finalPath,
        'tempPath': tempPath,
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'createdAt': createdAt.toIso8601String(),
        'error': error,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemTitle: json['itemTitle']?.toString() ?? '',
      seasonNumber: (json['seasonNumber'] as num?)?.toInt(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt(),
      label: json['label']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      finalPath: json['finalPath']?.toString() ?? '',
      tempPath: json['tempPath']?.toString() ?? '',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => DownloadStatus.failed,
      ),
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      error: json['error']?.toString(),
    );
  }
}
