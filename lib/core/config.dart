class AppConfig {
  const AppConfig._();

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');
  static const String omdbBaseUrl = 'https://www.omdbapi.com/';
  static const String omdbApiKey = String.fromEnvironment('OMDB_API_KEY', defaultValue: '');
  static const Duration cacheMaxAge = Duration(hours: 24);
}
