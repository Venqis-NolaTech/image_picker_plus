class FileUtil {
  static bool isThatVideo(String path) {
    final reg = RegExp(r'(?:3gp)|(?:mp4)|(?:webm)|(?:mov)|(?:mkv)');
    return path.toLowerCase().contains(reg, path.length - 5);
  }
}
