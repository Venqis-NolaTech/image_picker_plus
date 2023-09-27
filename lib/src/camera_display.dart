import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/camera_progress_button.dart';
import 'package:image_picker_plus/src/custom_packages/crop_image/main/image_crop.dart';
import 'package:image_picker_plus/src/entities/app_theme.dart';
import 'package:image_picker_plus/src/custom_packages/crop_image/crop_image.dart';
import 'package:image_picker_plus/src/entities/image_picker_display.dart';
import 'package:image_picker_plus/src/utilities/enum.dart';
import 'package:image_picker_plus/src/video_layout/record_count.dart';
import 'package:image_picker_plus/src/video_layout/record_fade_animation.dart';
import 'package:image_picker_plus/src/entities/selected_image_details.dart';
import 'package:image_picker_plus/src/entities/tabs_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CustomCameraDisplay extends StatefulWidget {
  final bool selectedVideo;
  final AppTheme appTheme;
  final TabsTexts tapsNames;
  final bool enableCamera;
  final bool enableVideo;
  final bool bothSource;
  final VoidCallback moveToVideoScreen;
  final VoidCallback? moveToGalleryScreen;
  final ValueNotifier<File?> selectedCameraImage;
  final ValueNotifier<File?> selectedCameraVideo;
  final List<FutureBuilder<Uint8List?>> mediaListCurrentAlbum;
  final ValueNotifier<bool> redDeleteText;
  final ValueChanged<bool> replacingTabBar;
  final ValueNotifier<bool> clearVideoRecord;
  final GalleryDisplaySettings galleryDisplaySettings;

  const CustomCameraDisplay({
    Key? key,
    required this.appTheme,
    required this.tapsNames,
    required this.selectedCameraImage,
    required this.selectedCameraVideo,
    required this.mediaListCurrentAlbum,
    required this.enableCamera,
    required this.enableVideo,
    required this.bothSource,
    required this.redDeleteText,
    required this.selectedVideo,
    required this.replacingTabBar,
    required this.clearVideoRecord,
    required this.moveToVideoScreen,
    required this.galleryDisplaySettings,
    this.moveToGalleryScreen,
  }) : super(key: key);

  @override
  CustomCameraDisplayState createState() => CustomCameraDisplayState();
}

class CustomCameraDisplayState extends State<CustomCameraDisplay> {
  ValueNotifier<bool> startVideoCount = ValueNotifier(false);
  ValueNotifier<Duration> recordStopwatch = ValueNotifier(Duration.zero);

  bool isShootingButtonAnimate = false;

  Timer? recordCountdownTimer;

  bool initializeDone = false;
  bool allPermissionsAccessed = true;

  List<CameraDescription>? cameras;
  late CameraController controller;

  final cropKey = GlobalKey<CustomCropState>();

  Flash currentFlashMode = Flash.auto;
  late Widget videoStatusAnimation;
  int selectedCamera = 0;

  bool get isRecordingRestricted =>
      widget.galleryDisplaySettings.maximumRecordingDuration != null;

  @override
  void dispose() {
    startVideoCount.dispose();
    controller.dispose();
    recordCountdownTimer?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    videoStatusAnimation = Container();
    _initializeCamera();

    super.initState();
  }

  Future<void> _initializeCamera() async {
    try {
      PermissionState state = await PhotoManager.requestPermissionExtend();
      if (!state.hasAccess || !state.isAuth) {
        allPermissionsAccessed = false;
        return;
      }
      allPermissionsAccessed = true;
      cameras = await availableCameras();
      if (!mounted) return;
      controller = CameraController(
        cameras![selectedCamera],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      initializeDone = true;
    } catch (e) {
      allPermissionsAccessed = false;
    }
    setState(() {});
  }

  Future<void> _startRecordingVideo() async {
    if (controller.value.isRecordingVideo) {
      return;
    }

    await controller.startVideoRecording();
    widget.moveToVideoScreen();
    if (isRecordingRestricted) {
      recordCountdownTimer = Timer(
        widget.galleryDisplaySettings.maximumRecordingDuration!,
        _stopRecordingVideo,
      );
    }
  }

  Future<void> _stopRecordingVideo() async {
    void handleError() {
      recordCountdownTimer?.cancel();
      isShootingButtonAnimate = false;
      setState(() {});
    }

    if (!controller.value.isRecordingVideo) {
      handleError();
      return;
    }

    setState(() {
      startVideoCount.value = false;
      isShootingButtonAnimate = false;
      widget.replacingTabBar(true);
    });

    final XFile video = await controller.stopVideoRecording();
    if (recordStopwatch.value <
        widget.galleryDisplaySettings.minimumRecordingDuration) {
      return;
    }
    File selectedVideo = File(video.path);

    setState(() {
      widget.selectedCameraVideo.value = selectedVideo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: widget.galleryDisplaySettings.appThemeCameraInvert
          ? widget.appTheme.focusColor
          : widget.appTheme.primaryColor,
      appBar: appBar(),
      body: allPermissionsAccessed
          ? (initializeDone ? buildBody() : loadingProgress())
          : failedPermissions(),
    );
  }

  Widget failedPermissions() {
    return Center(
      child: Text(
        widget.tapsNames.acceptAllPermissions,
        style: TextStyle(
            color: widget.galleryDisplaySettings.appThemeCameraInvert
                ? widget.appTheme.primaryColor
                : widget.appTheme.focusColor),
      ),
    );
  }

  Center loadingProgress() {
    return Center(
      child: CircularProgressIndicator(
        color: widget.galleryDisplaySettings.appThemeCameraInvert
            ? widget.appTheme.primaryColor
            : widget.appTheme.focusColor,
        strokeWidth: 1,
      ),
    );
  }

  Widget buildBody() {
    Color whiteColor = widget.galleryDisplaySettings.appThemeCameraInvert
        ? widget.appTheme.focusColor
        : widget.appTheme.primaryColor;
    File? selectedImage = widget.selectedCameraImage.value;
    File? selectedVideo = widget.selectedCameraVideo.value;

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Stack(
      children: [
        selectedImage == null && selectedVideo == null
            ? SizedBox(
                height: height,
                width: width,
                child: CameraPreview(controller),
              )
            : SizedBox(
                height: height,
                width: width,
                child: buildCrop(selectedImage ?? selectedVideo!),
              ),
        selectedImage == null && selectedVideo == null
            ? buildPickImageContainer(whiteColor, context)
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget buildPickImageContainer(Color color, BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 270,
        color: color.withOpacity(0.6),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RecordCount(
              appTheme: widget.appTheme,
              appThemeCameraInvert:
                  widget.galleryDisplaySettings.appThemeCameraInvert,
              startVideoCount: startVideoCount,
              clearVideoRecord: widget.clearVideoRecord,
              recordStopwatch: recordStopwatch,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                widget.bothSource
                    ? buildGallery()
                    : Container(
                        padding: const EdgeInsets.only(left: 32),
                        width: 48,
                        height: 48,
                      ),
                const SizedBox(width: 16),
                Align(
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      cameraButton(context),
                      Positioned(top: 0, child: videoStatusAnimation),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                buildToggleCamera(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Align buildGallery() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: GestureDetector(
          onTap: widget.moveToGalleryScreen,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey,
                border: Border.all(
                  width: 0.5,
                  color: widget.appTheme.accentColor,
                )),
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.mediaListCurrentAlbum.isNotEmpty
                  ? widget.mediaListCurrentAlbum.first
                  : const Icon(Icons.image),
            ),
          ),
        ),
      ),
    );
  }

  Align buildToggleCamera() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: IconButton(
          onPressed: () {
            selectedCamera = selectedCamera == 0 ? 1 : 0;
            _initializeCamera();
          },
          icon: Icon(
            Platform.isIOS ? Icons.flip_camera_ios : Icons.flip_camera_android,
            color: widget.galleryDisplaySettings.appThemeCameraInvert
                ? widget.appTheme.primaryColor
                : widget.appTheme.focusColor,
          ),
        ),
      ),
    );
  }

  Align buildFlashIcons() {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        onPressed: () {
          setState(() {
            currentFlashMode = currentFlashMode == Flash.off
                ? Flash.auto
                : (currentFlashMode == Flash.auto ? Flash.on : Flash.off);
          });
          currentFlashMode == Flash.on
              ? controller.setFlashMode(FlashMode.torch)
              : currentFlashMode == Flash.off
                  ? controller.setFlashMode(FlashMode.off)
                  : controller.setFlashMode(FlashMode.auto);
        },
        icon: Icon(
          currentFlashMode == Flash.on
              ? Icons.flash_on_rounded
              : (currentFlashMode == Flash.auto
                  ? Icons.flash_auto_rounded
                  : Icons.flash_off_rounded),
          color: widget.galleryDisplaySettings.appThemeCameraInvert
              ? widget.appTheme.primaryColor
              : widget.appTheme.focusColor,
        ),
      ),
    );
  }

  CustomCrop buildCrop(File selectedFile) {
    String path = selectedFile.path;
    bool isThatVideo = path.contains("mp4", path.length - 5);

    return CustomCrop(
      image: selectedFile,
      isThatImage: !isThatVideo,
      key: cropKey,
      alwaysShowGrid: true,
      paintColor: widget.galleryDisplaySettings.appThemeCameraInvert
          ? widget.appTheme.focusColor
          : widget.appTheme.primaryColor,
    );
  }

  AppBar appBar() {
    Color whiteColor = widget.galleryDisplaySettings.appThemeCameraInvert
        ? widget.appTheme.focusColor
        : widget.appTheme.primaryColor;
    Color blackColor = widget.galleryDisplaySettings.appThemeCameraInvert
        ? widget.appTheme.primaryColor
        : widget.appTheme.focusColor;
    File? selectedImage = widget.selectedCameraImage.value;
    File? selectedVideo = widget.selectedCameraVideo.value;

    return AppBar(
      backgroundColor: whiteColor.withOpacity(0.6),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.clear_rounded, color: blackColor, size: 30),
        onPressed: () {
          widget.bothSource
              ? widget.moveToGalleryScreen?.call()
              : Navigator.of(context).maybePop(null);
        },
      ),
      actions: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeIn,
          child: selectedVideo == null && selectedImage == null
              ? buildFlashIcons()
              : doneBtn(selectedVideo, selectedImage),
        ),
      ],
    );
  }

  Widget doneBtn(File? selectedVideo, File? selectedImage) {
    return IconButton(
      icon: Icon(Icons.arrow_forward_rounded,
          color: widget.appTheme.accentColor, size: 30),
      onPressed: () async {
        if (selectedVideo != null) {
          Uint8List byte = await selectedVideo.readAsBytes();

          SelectedImage selectedByte = SelectedImage(
            isThatImage: false,
            selectedFile: selectedVideo,
            selectedByte: byte,
          );
          SelectedImagesDetails details = SelectedImagesDetails(
            multiSelectionMode: false,
            selectedFiles: [selectedByte],
            aspectRatio: 1.0,
          );
          if (!mounted) return;
          Navigator.of(context).maybePop(details);
        } else if (selectedImage != null) {
          File? croppedByte = await cropImage(selectedImage);
          if (croppedByte != null) {
            Uint8List byte = await croppedByte.readAsBytes();

            SelectedImage selectedByte = SelectedImage(
              isThatImage: true,
              selectedFile: croppedByte,
              selectedByte: byte,
            );

            SelectedImagesDetails details = SelectedImagesDetails(
              selectedFiles: [selectedByte],
              multiSelectionMode: false,
              aspectRatio: 1.0,
            );
            if (!mounted) return;
            Navigator.of(context).maybePop(details);
          }
        }
      },
    );
  }

  Future<File?> cropImage(File imageFile) async {
    await ImageCrop.requestPermissions();
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState!.area;
    if (area == null) {
      return null;
    }
    final sample = await ImageCrop.sampleImage(
      file: imageFile,
      preferredSize: (2000 / scale).round(),
    );
    final File file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );
    sample.delete();
    return file;
  }

  Widget cameraButton(BuildContext context) {
    Color whiteColor = widget.galleryDisplaySettings.appThemeCameraInvert
        ? widget.appTheme.focusColor
        : widget.appTheme.primaryColor;

    const Size outerSize = Size.square(115);
    const Size innerSize = Size.square(82);

    return GestureDetector(
      onTap: widget.enableCamera ? onTap : null,
      onLongPress: widget.enableVideo ? onLongTap : null,
      onLongPressUp: widget.enableVideo ? onLongTapUp : onTap,
      child: SizedBox.fromSize(
        size: outerSize,
        child: Stack(
          children: [
            Center(
              child: AnimatedContainer(
                duration: kThemeChangeDuration,
                width:
                    isShootingButtonAnimate ? outerSize.width : innerSize.width,
                height: isShootingButtonAnimate
                    ? outerSize.height
                    : innerSize.height,
                padding: EdgeInsets.all(isShootingButtonAnimate ? 41 : 11),
                decoration: BoxDecoration(
                  color: whiteColor.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (controller.value.isRecordingVideo)
              CameraProgressButton(
                isAnimating: isShootingButtonAnimate,
                duration:
                    widget.galleryDisplaySettings.maximumRecordingDuration!,
                outerRadius: outerSize.width,
                ringsColor: widget.appTheme.accentColor,
                ringsWidth: 2,
              ),
          ],
        ),
      ),
    );
  }

  onTap() async {
    try {
      if (!widget.selectedVideo) {
        final image = await controller.takePicture();
        File selectedImage = File(image.path);

        setState(() {
          widget.selectedCameraImage.value = selectedImage;
          widget.replacingTabBar(true);
        });
      } else {
        setState(() {
          videoStatusAnimation = buildFadeAnimation();
        });
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  onLongTap() async {
    _startRecordingVideo();
    setState(() {
      startVideoCount.value = true;
      isShootingButtonAnimate = true;
    });
  }

  onLongTapUp() async {
    _stopRecordingVideo();
  }

  RecordFadeAnimation buildFadeAnimation() {
    return RecordFadeAnimation(child: buildMessage());
  }

  Widget buildMessage() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            color: Color.fromARGB(255, 54, 53, 53),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.tapsNames.holdButtonText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Center(
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: Color.fromARGB(255, 49, 49, 49),
              size: 65,
            ),
          ),
        ),
      ],
    );
  }
}
