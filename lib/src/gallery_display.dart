import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:image_picker_plus/src/camera_display.dart';
import 'package:image_picker_plus/src/images_view_page.dart';
import 'package:image_picker_plus/src/utilities/enum.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomImagePicker extends StatefulWidget {
  final ImageSource source;
  final bool multiSelection;
  final GalleryDisplaySettings galleryDisplaySettings;
  final PickerSource pickerSource;
  const CustomImagePicker({
    required this.source,
    required this.multiSelection,
    required this.galleryDisplaySettings,
    required this.pickerSource,
    super.key,
  });

  @override
  CustomImagePickerState createState() => CustomImagePickerState();
}

class CustomImagePickerState extends State<CustomImagePicker>
    with TickerProviderStateMixin {
  final pageController = ValueNotifier(PageController());
  final clearVideoRecord = ValueNotifier(false);
  final redDeleteText = ValueNotifier(false);
  final selectedPage = ValueNotifier(SelectedPage.left);
  ValueNotifier<List<File>> multiSelectedImage = ValueNotifier([]);
  final multiSelectionMode = ValueNotifier(false);
  final showDeleteText = ValueNotifier(false);
  final selectedVideo = ValueNotifier(false);
  bool noGallery = true;
  ValueNotifier<File?> selectedCameraImage = ValueNotifier(null);
  ValueNotifier<File?> selectedCameraVideo = ValueNotifier(null);
  late bool cropImage;
  late AppTheme appTheme;
  late TabsTexts tapsNames;
  late AlbumTexts albumNames;
  late bool showImagePreview;
  late int maximumSelection;
  late ButtonStyle? multiSelectIconBtnStyle;
  late ButtonStyle? cameraBtnStyle;
  late Icon? multiSelectIcon;
  late Icon? cameraIcon;
  late int? cacheSizeImage;
  late int pageImageSize;
  late bool bytesArrayExport;
  final isImagesReady = ValueNotifier(false);
  final currentPage = ValueNotifier(0);
  final lastPage = ValueNotifier(0);

  late Color whiteColor;
  late Color blackColor;
  late GalleryDisplaySettings imagePickerDisplay;

  late bool enableCamera;
  late bool enableVideo;
  late String limitingText;

  late bool showInternalVideos;
  late bool showInternalImages;
  late SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  late bool cameraAndVideoEnabled;
  late bool cameraVideoOnlyEnabled;
  late bool showAllTabs;
  late AsyncValueSetter<SelectedImagesDetails>? callbackFunction;

  ValueNotifier<List<FutureBuilder<Uint8List?>>> mediaListCurrentAlbum =
      ValueNotifier([]);

  @override
  void initState() {
    _initializeVariables();
    super.initState();
  }

  _initializeVariables() {
    imagePickerDisplay = widget.galleryDisplaySettings;
    appTheme = imagePickerDisplay.appTheme ?? AppTheme();
    tapsNames = imagePickerDisplay.tabsTexts ?? TabsTexts();
    albumNames = imagePickerDisplay.albumTexts ?? AlbumTexts();
    callbackFunction = imagePickerDisplay.callbackFunction;
    cropImage = imagePickerDisplay.cropImage;
    maximumSelection = imagePickerDisplay.maximumSelection;
    limitingText = tapsNames.limitingText ??
        "The limit is $maximumSelection photos or videos.";

    multiSelectIconBtnStyle = imagePickerDisplay.multiSelectIconBtnStyle;
    cameraBtnStyle = imagePickerDisplay.cameraBtnStyle;
    multiSelectIcon = imagePickerDisplay.multiSelectIcon;
    cameraIcon = imagePickerDisplay.cameraIcon;

    cacheSizeImage = imagePickerDisplay.cacheSizeImage;
    pageImageSize = imagePickerDisplay.pageImageSize;

    bytesArrayExport = imagePickerDisplay.byteArrayExport;

    showImagePreview = cropImage || imagePickerDisplay.showImagePreview;
    gridDelegate = imagePickerDisplay.gridDelegate;

    showInternalImages = widget.pickerSource != PickerSource.video;
    showInternalVideos = widget.pickerSource != PickerSource.image;

    noGallery = widget.source != ImageSource.camera;
    bool notGallery = widget.source != ImageSource.gallery;

    enableCamera = showInternalImages && notGallery;
    enableVideo = showInternalVideos && notGallery;
    cameraAndVideoEnabled = enableCamera && enableVideo;
    cameraVideoOnlyEnabled =
        cameraAndVideoEnabled && widget.source == ImageSource.camera;
    showAllTabs = cameraAndVideoEnabled && noGallery;
    whiteColor = appTheme.primaryColor;
    blackColor = appTheme.focusColor;
  }

  @override
  void dispose() {
    showDeleteText.dispose();
    selectedVideo.dispose();
    selectedPage.dispose();
    selectedCameraImage.dispose();
    selectedCameraVideo.dispose();
    pageController.dispose();
    clearVideoRecord.dispose();
    redDeleteText.dispose();
    multiSelectionMode.dispose();
    multiSelectedImage.dispose();
    super.dispose();
  }

  bool topSafeArea() {
    switch (widget.source) {
      case ImageSource.both:
        return selectedPage.value == SelectedPage.left;
      case ImageSource.camera:
        return false;
      case ImageSource.gallery:
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.source == ImageSource.both) {
          if (selectedPage.value != SelectedPage.left &&
              (selectedCameraImage.value == null &&
                  selectedCameraVideo.value == null)) {
            moveToGallery();

            return false;
          }
          return true;
        }
        return true;
      },
      child: tabController(),
    );
  }

  Widget tapBarMessage(bool isThatDeleteText) {
    Color deleteColor = redDeleteText.value ? Colors.red : appTheme.focusColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: GestureDetector(
          onTap: () async {
            if (isThatDeleteText) {
              setState(() {
                if (!redDeleteText.value) {
                  redDeleteText.value = true;
                } else {
                  selectedCameraImage.value = null;
                  selectedCameraVideo.value = null;
                  clearVideoRecord.value = true;
                  showDeleteText.value = false;
                  redDeleteText.value = false;
                }
              });
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isThatDeleteText)
                Icon(Icons.arrow_back_ios_rounded,
                    color: deleteColor, size: 15),
              Text(
                isThatDeleteText ? tapsNames.deletingText : limitingText,
                style: TextStyle(
                    fontSize: 14,
                    color: deleteColor,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget clearSelectedImages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: GestureDetector(
          onTap: () async {
            setState(() {
              multiSelectionMode.value = !multiSelectionMode.value;
              multiSelectedImage.value.clear();
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                tapsNames.clearImagesText,
                style: TextStyle(
                    fontSize: 14,
                    color: appTheme.focusColor,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  replacingDeleteWidget(bool showDeleteText) {
    this.showDeleteText.value = showDeleteText;
  }

  moveToVideo() {
    setState(() {
      selectedPage.value = SelectedPage.right;
      selectedVideo.value = true;
    });
  }

  moveToCamera() {
    centerPage(
      numPage: cameraVideoOnlyEnabled ? 0 : 1,
      selectedPage:
          cameraVideoOnlyEnabled ? SelectedPage.left : SelectedPage.center,
    );
  }

  moveToGallery() {
    setState(() {
      selectedPage.value = SelectedPage.left;
      selectedVideo.value = false;
    });
    pageController.value.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuad,
    );
  }

  DefaultTabController tabController() {
    return DefaultTabController(
        length: 2, child: Material(color: whiteColor, child: safeArea()));
  }

  SafeArea safeArea() {
    return SafeArea(
      top: topSafeArea(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: pageController,
              builder: (context, PageController pageControllerValue, child) =>
                  PageView(
                controller: pageControllerValue,
                dragStartBehavior: DragStartBehavior.start,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  if (noGallery) imagesViewPage(),
                  if (enableCamera || enableVideo) cameraPage(),
                ],
              ),
            ),
          ),
          if (multiSelectedImage.value.length < maximumSelection) ...[
            ValueListenableBuilder(
              valueListenable: multiSelectionMode,
              builder: (context, bool multiSelectionModeValue, child) {
                if (enableVideo || enableCamera) {
                  if (!showImagePreview) {
                    if (multiSelectionModeValue) {
                      return clearSelectedImages();
                    }
                  }

                  return const SizedBox.shrink();
                } else {
                  return multiSelectionModeValue
                      ? clearSelectedImages()
                      : const SizedBox();
                }
              },
            )
          ] else ...[
            tapBarMessage(false)
          ],
        ],
      ),
    );
  }

  ValueListenableBuilder<bool> cameraPage() {
    return ValueListenableBuilder(
      valueListenable: selectedVideo,
      builder: (context, bool selectedVideoValue, child) => CustomCameraDisplay(
        appTheme: appTheme,
        galleryDisplaySettings: widget.galleryDisplaySettings,
        selectedCameraImage: selectedCameraImage,
        selectedCameraVideo: selectedCameraVideo,
        tapsNames: tapsNames,
        enableCamera: enableCamera,
        enableVideo: enableVideo,
        replacingTabBar: replacingDeleteWidget,
        clearVideoRecord: clearVideoRecord,
        redDeleteText: redDeleteText,
        moveToVideoScreen: moveToVideo,
        bothSource: widget.source == ImageSource.both,
        moveToGalleryScreen: moveToGallery,
        selectedVideo: selectedVideoValue,
        mediaListCurrentAlbum: mediaListCurrentAlbum.value,
      ),
    );
  }

  void clearMultiImages() {
    setState(() {
      multiSelectedImage.value.clear();
      multiSelectionMode.value = false;
    });
  }

  ImagesViewPage imagesViewPage() {
    return ImagesViewPage(
      appTheme: appTheme,
      clearMultiImages: clearMultiImages,
      callbackFunction: callbackFunction,
      gridDelegate: gridDelegate,
      multiSelectionMode: multiSelectionMode,
      blackColor: blackColor,
      showImagePreview: showImagePreview,
      tabsTexts: tapsNames,
      albumTexts: albumNames,
      multiSelectedImages: multiSelectedImage,
      whiteColor: whiteColor,
      cropImage: cropImage,
      multiSelection: widget.multiSelection,
      showInternalVideos: showInternalVideos,
      showInternalImages: showInternalImages,
      maximumSelection: maximumSelection,
      moveToCamera: moveToCamera,
      mediaListCurrentAlbum: mediaListCurrentAlbum,
      multiSelectIconBtnStyle: multiSelectIconBtnStyle,
      cameraBtnStyle: cameraBtnStyle,
      multiSelectIcon: multiSelectIcon,
      cameraIcon: cameraIcon,
      enableCamera: enableCamera,
      enableVideo: enableVideo,
      cacheSizeImage: cacheSizeImage,
      pageImageSize: pageImageSize,
      bytesArrayExport: bytesArrayExport,
    );
  }

  GestureDetector galleryTabBar(
      double widthOfTab, SelectedPage selectedPageValue) {
    return GestureDetector(
      onTap: () {
        setState(() {
          centerPage(numPage: 0, selectedPage: SelectedPage.left);
        });
      },
      child: SizedBox(
        width: widthOfTab,
        height: 40,
        child: Center(
          child: Text(
            tapsNames.galleryText,
            style: TextStyle(
                color: selectedPageValue == SelectedPage.left
                    ? blackColor
                    : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  GestureDetector photoTabBar(double widthOfTab, Color textColor) {
    return GestureDetector(
      onTap: () => centerPage(
          numPage: cameraVideoOnlyEnabled ? 0 : 1,
          selectedPage:
              cameraVideoOnlyEnabled ? SelectedPage.left : SelectedPage.center),
      child: SizedBox(
        width: widthOfTab,
        height: 40,
        child: Center(
          child: Text(
            tapsNames.photoText,
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  centerPage({required int numPage, required SelectedPage selectedPage}) {
    if (!enableVideo && numPage == 1) selectedPage = SelectedPage.right;

    setState(() {
      this.selectedPage.value = selectedPage;
      pageController.value.animateToPage(numPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuad);
      selectedVideo.value = false;
    });
  }

  GestureDetector videoTabBar(double widthOfTab) {
    return GestureDetector(
      onTap: () {
        setState(
          () {
            pageController.value.animateToPage(cameraVideoOnlyEnabled ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutQuad);
            selectedPage.value = SelectedPage.right;
            selectedVideo.value = true;
          },
        );
      },
      child: SizedBox(
        width: widthOfTab,
        height: 40,
        child: ValueListenableBuilder(
          valueListenable: selectedVideo,
          builder: (context, bool selectedVideoValue, child) => Center(
            child: Text(
              tapsNames.videoText,
              style: TextStyle(
                  fontSize: 14,
                  color: selectedVideoValue ? blackColor : Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
