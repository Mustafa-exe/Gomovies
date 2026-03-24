import 'package:video_player/video_player.dart';

VideoPlayerController createVideoController({
  required String source,
  required bool isLocal,
}) {
  if (isLocal) {
    throw UnsupportedError('Offline file playback is not supported on web builds.');
  }
  return VideoPlayerController.networkUrl(Uri.parse(source));
}
