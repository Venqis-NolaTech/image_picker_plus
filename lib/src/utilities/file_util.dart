class FileUtil {
  static bool isThatVideo(path) {
    final reg = RegExp(r'(?:3gp)|(?:mp4)|(?:webm)|(?:mov)|(?:mkv)');
    return path.contains(reg, path.length - 5);
  }
}
