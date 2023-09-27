import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/material.dart';

/// [GalleryDisplaySettings] When you make ImageSource from the camera these settings will be disabled because they belong to the gallery.
class GalleryDisplaySettings {
  AppTheme? appTheme;
  TabsTexts? tabsTexts;
  AlbumTexts? albumTexts;
  SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  bool showImagePreview;
  int maximumSelection;
  final AsyncValueSetter<SelectedImagesDetails>? callbackFunction;

  /// If [cropImage] true [showImagePreview] will be true
  /// Right now this package not support crop video
  bool cropImage;

  /// The maximum duration of the video recording process.
  ///
  /// Defaults to 15 seconds, allow `null` for unrestricted video recording.
  final Duration? maximumRecordingDuration;

  /// The minimum duration of the video recording process.
  ///
  /// Defaults to and cannot be lower than 1 second.
  final Duration minimumRecordingDuration;

  /// If [appThemeCameraInvert] true [AppTheme] colors invert on camera.
  final bool appThemeCameraInvert;

  /// If [bytesArrayExport] true export file will be [Uint8List].
  final bool byteArrayExport;

  /// [ButtonStyle] of multiSelectIconBtn
  final ButtonStyle? multiSelectIconBtnStyle;

  /// [ButtonStyle] of cameraBtn
  final ButtonStyle? cameraBtnStyle;

  /// [Icon] of multiSelectIconBtn
  final Icon? multiSelectIcon;

  /// [Icon] of cameraBtn
  final Icon? cameraIcon;

  /// [int] size of cache image
  final int? cacheSizeImage;

  /// [int] size of page image
  final int pageImageSize;

  GalleryDisplaySettings({
    this.appTheme,
    this.tabsTexts,
    this.albumTexts,
    this.callbackFunction,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 1.7, mainAxisSpacing: 1.5),
    this.showImagePreview = false,
    this.cropImage = false,
    this.appThemeCameraInvert = false,
    this.byteArrayExport = true,
    this.maximumSelection = 10,
    this.maximumRecordingDuration = const Duration(seconds: 30),
    this.minimumRecordingDuration = const Duration(seconds: 1),
    this.multiSelectIconBtnStyle,
    this.cameraBtnStyle,
    this.multiSelectIcon,
    this.cameraIcon,
    this.cacheSizeImage,
    this.pageImageSize = 60,
  });
}
