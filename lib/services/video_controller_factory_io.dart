import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createVideoController({
  required String source,
  required bool isLocal,
}) {
  return isLocal
      ? VideoPlayerController.file(File(source))
      : VideoPlayerController.networkUrl(Uri.parse(source));
}
