import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/material.dart';

/// [GalleryDisplaySettings] When you make ImageSource from the camera these settings will be disabled because they belong to the gallery.
class GalleryDisplaySettings {
  AppTheme? appTheme;
  TabsTexts? tabsTexts;
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

  /// [ButtonStyle] of multiSelectIconBtn
  final ButtonStyle? multiSelectIconBtnStyle;

  /// [ButtonStyle] of cameraBtn
  final ButtonStyle? cameraBtnStyle;

  /// [Icon] of multiSelectIconBtn
  final Icon? multiSelectIcon;

  /// [Icon] of cameraBtn
  final Icon? cameraIcon;

  GalleryDisplaySettings({
    this.appTheme,
    this.tabsTexts,
    this.callbackFunction,
    this.gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 1.7, mainAxisSpacing: 1.5),
    this.showImagePreview = false,
    this.cropImage = false,
    this.appThemeCameraInvert = false,
    this.maximumSelection = 10,
    this.maximumRecordingDuration = const Duration(seconds: 15),
    this.minimumRecordingDuration = const Duration(seconds: 1),
    this.multiSelectIconBtnStyle,
    this.cameraBtnStyle,
    this.multiSelectIcon,
    this.cameraIcon,
  });
}
