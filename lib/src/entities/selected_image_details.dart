import 'dart:io';

import 'package:flutter/foundation.dart';

class SelectedImagesDetails {
  List<SelectedImage> selectedFiles;
  double aspectRatio;
  bool multiSelectionMode;

  SelectedImagesDetails({
    required this.selectedFiles,
    required this.aspectRatio,
    required this.multiSelectionMode,
  });
}

class SelectedImage {
  File selectedFile;
  Uint8List? selectedByte;

  bool isThatImage;
  SelectedImage({
    required this.isThatImage,
    required this.selectedFile,
    this.selectedByte,
  });
}
