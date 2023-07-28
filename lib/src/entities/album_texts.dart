import 'package:collection/collection.dart';

enum Album {
  videos,
  pictures,
  cameras,
  movies,
  screenshots,
  download,
  restored,
  recent,
}

extension AlbumExt on Album {
  static Album? find(String name) => Album.values
      .firstWhereOrNull((e) => e.name.toLowerCase() == name.toLowerCase());
}

class AlbumTexts {
  final String videos;
  final String pictures;
  final String cameras;
  final String movies;
  final String screenshots;
  final String download;
  final String restored;
  final String recent;

  AlbumTexts({
    this.videos = "Videos",
    this.pictures = "Pictures",
    this.cameras = "Cameras",
    this.movies = "Movies",
    this.screenshots = "Screenshots",
    this.download = "Download",
    this.restored = "Restored",
    this.recent = "Recent",
  });
}
