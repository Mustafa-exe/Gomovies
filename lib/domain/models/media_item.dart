enum MediaType { movie, show, anime, documentary, live, other }

class MediaVariant {
  const MediaVariant({
    required this.id,
    required this.qualityLabel,
    required this.bitrate,
    required this.url,
  });

  final String id;
  final String qualityLabel;
  final int bitrate;
  final String url;

  factory MediaVariant.fromJson(Map<String, dynamic> json) {
    return MediaVariant(
      id: json['id']?.toString() ?? '',
      qualityLabel: json['qualityLabel']?.toString() ?? 'Auto',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'qualityLabel': qualityLabel,
        'bitrate': bitrate,
        'url': url,
      };
}

class Episode {
  const Episode({
    required this.id,
    required this.number,
    required this.title,
    required this.durationSec,
    required this.variants,
  });

  final String id;
  final int number;
  final String title;
  final int durationSec;
  final List<MediaVariant> variants;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Episode',
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map((e) => MediaVariant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'durationSec': durationSec,
        'variants': variants.map((e) => e.toJson()).toList(),
      };
}

class Season {
  const Season({
    required this.id,
    required this.number,
    required this.title,
    required this.episodes,
  });

  final String id;
  final int number;
  final String title;
  final List<Episode> episodes;

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? 'Season',
      episodes: (json['episodes'] as List<dynamic>? ?? const [])
          .map((e) => Episode.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'title': title,
        'episodes': episodes.map((e) => e.toJson()).toList(),
      };
}

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.mediaType,
    required this.seasons,
    required this.variants,
    required this.source,
    required this.releaseYear,
  });

  final String id;
  final String title;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final MediaType mediaType;
  final List<Season> seasons;
  final List<MediaVariant> variants;
  final String source;
  final String releaseYear;

  bool get isSeries => seasons.isNotEmpty;

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      overview: json['overview']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
      backdropUrl: json['backdropUrl']?.toString() ?? '',
      mediaType: _parseMediaType(json['mediaType']?.toString()),
      seasons: (json['seasons'] as List<dynamic>? ?? const [])
          .map((e) => Season.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map((e) => MediaVariant.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      source: json['source']?.toString() ?? 'unknown',
      releaseYear: json['releaseYear']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'posterUrl': posterUrl,
        'backdropUrl': backdropUrl,
        'mediaType': mediaType.name,
        'seasons': seasons.map((e) => e.toJson()).toList(),
        'variants': variants.map((e) => e.toJson()).toList(),
        'source': source,
        'releaseYear': releaseYear,
      };

  static MediaType _parseMediaType(String? value) {
    return MediaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MediaType.other,
    );
  }
}
