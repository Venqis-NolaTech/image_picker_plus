import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/custom_expand_icon.dart';
import 'package:image_picker_plus/src/custom_packages/crop_image/crop_image.dart';
import 'package:image_picker_plus/src/entities/app_theme.dart';
import 'package:image_picker_plus/src/entities/path_wrapper.dart';
import 'package:image_picker_plus/src/scale_text.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker_plus/src/utilities/extension.dart';

class CropImageView extends StatefulWidget {
  final ValueNotifier<GlobalKey<CustomCropState>> cropKey;
  final ValueNotifier<List<int>> indexOfSelectedImages;

  final ValueNotifier<bool> multiSelectionMode;
  final ValueNotifier<bool> expandImage;
  final ValueNotifier<double> expandHeight;
  final ValueNotifier<bool> expandImageView;

  /// To avoid lag when you interacting with image when it expanded
  final ValueNotifier<bool> enableVerticalTapping;
  final ValueNotifier<File?> selectedImage;

  final VoidCallback clearMultiImages;
  final VoidCallback? moveToCamera;

  final AppTheme appTheme;
  final ValueNotifier<bool> noDuration;
  final Color whiteColor;
  final double? topPosition;

  final bool enableCamera;
  final bool enableVideo;

  final ButtonStyle? multiSelectIconBtnStyle;
  final ButtonStyle? cameraBtnStyle;
  final Icon? multiSelectIcon;
  final Icon? cameraIcon;

  final List<PathWrapper<AssetPathEntity>> assetPaths;
  final PathWrapper<AssetPathEntity>? assetPathSelected;
  final Function(PathWrapper<AssetPathEntity>?) onAssetPathChanged;

  const CropImageView({
    Key? key,
    required this.indexOfSelectedImages,
    required this.cropKey,
    required this.multiSelectionMode,
    required this.expandImage,
    required this.expandHeight,
    required this.clearMultiImages,
    required this.expandImageView,
    required this.enableVerticalTapping,
    required this.selectedImage,
    required this.appTheme,
    required this.noDuration,
    required this.whiteColor,
    required this.assetPaths,
    required this.onAssetPathChanged,
    required this.enableCamera,
    required this.enableVideo,
    this.assetPathSelected,
    this.topPosition,
    this.moveToCamera,
    this.multiSelectIconBtnStyle,
    this.cameraBtnStyle,
    this.multiSelectIcon,
    this.cameraIcon,
  }) : super(key: key);

  @override
  State<CropImageView> createState() => _CropImageViewState();
}

class _CropImageViewState extends State<CropImageView> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width + kToolbarHeight;

    return ValueListenableBuilder(
      valueListenable: widget.enableVerticalTapping,
      builder: (context, bool enableTappingValue, child) => GestureDetector(
        onVerticalDragUpdate: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandImageView.value = true;
                widget.expandHeight.value = details.globalPosition.dy - 50;
                setState(() => widget.noDuration.value = true);
              }
            : null,
        onVerticalDragEnd: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandHeight.value =
                    widget.expandHeight.value > 260 ? height : 0;
                if (widget.topPosition == -height) {
                  widget.enableVerticalTapping.value = true;
                }
                if (widget.topPosition == 0) {
                  widget.enableVerticalTapping.value = false;
                }
                setState(() => widget.noDuration.value = false);
              }
            : null,
        child: ValueListenableBuilder(
          valueListenable: widget.selectedImage,
          builder: (context, File? selectedImageValue, child) {
            if (selectedImageValue != null) {
              return showSelectedImage(context, selectedImageValue);
            } else {
              return Container(key: GlobalKey(debugLabel: "do not have"));
            }
          },
        ),
      ),
    );
  }

  Container showSelectedImage(BuildContext context, File selectedImageValue) {
    double width = MediaQuery.of(context).size.width;
    final height = width + kToolbarHeight;

    String path = selectedImageValue.path;
    bool isThatVideo = path.contains("mp4", path.length - 5);

    return Container(
      key: GlobalKey(debugLabel: "have image"),
      color: widget.whiteColor,
      height: height,
      width: width,
      child: ValueListenableBuilder(
        valueListenable: widget.multiSelectionMode,
        builder: (context, bool multiSelectionModeValue, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ValueListenableBuilder(
                      valueListenable: widget.expandImage,
                      builder: (context, bool expandImageValue, child) =>
                          _cropImageWidget(selectedImageValue, expandImageValue,
                              isThatVideo)),
                  if (!isThatVideo)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _cropIconBtn(),
                    ),
                ],
              ),
            ),
            _bottomPanelWidget(multiSelectionModeValue, isThatVideo),
          ],
        ),
      ),
    );
  }

  Widget _cropImageWidget(
    File selectedImageValue,
    bool expandImageValue,
    bool isThatVideo,
  ) {
    GlobalKey<CustomCropState> cropKey = widget.cropKey.value;

    return CustomCrop(
      image: selectedImageValue,
      isThatImage: !isThatVideo,
      key: cropKey,
      paintColor: widget.appTheme.primaryColor,
      aspectRatio: expandImageValue ? 6 / 8 : 1.0,
    );
  }

  Widget _bottomPanelWidget(bool multiSelectionModeValue, bool isThatVideo) {
    return Container(
      color: widget.appTheme.primaryColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(right: 8),
      height: kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _pathsDropDownButton(),
          const Spacer(),
          if (widget.topPosition != null)
            _multiSelectBtn(multiSelectionModeValue),
          if (widget.enableCamera || widget.enableVideo)
            _cameraBtn(multiSelectionModeValue),
        ],
      ),
    );
  }

  Widget _pathsDropDownButton() {
    final items = widget.assetPaths.where((e) => (e.assetCount ?? 0) > 0);

    return DropdownButtonHideUnderline(
      child: DropdownButton<PathWrapper<AssetPathEntity>>(
        value: widget.assetPathSelected,
        items: items.map(
          (path) {
            final wrapper = path.path;

            final isSelected = widget.assetPathSelected?.path == wrapper;
            final name = wrapper.name;

            return DropdownMenuItem<PathWrapper<AssetPathEntity>>(
              value: path,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ScaleText(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FutureBuilder<int>(
                    future: wrapper.assetCountAsync,
                    builder: (context, snapshot) {
                      int semanticsCount = 0;

                      if (snapshot.hasData) {
                        semanticsCount = snapshot.data ?? 0;
                      }

                      return ScaleText(
                        '($semanticsCount)',
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  if (isSelected)
                    const AspectRatio(
                      aspectRatio: 1,
                      child: Icon(Icons.check, color: Colors.blue, size: 26),
                    ),
                ],
              ),
            );
          },
        ).toList(),
        selectedItemBuilder: (context) {
          return widget.assetPaths.map((path) {
            final wrapper = path.path;
            final name = wrapper.name;

            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 12),
              child: ScaleText(
                name,
                style: TextStyle(
                  fontSize: 17,
                  color: widget.appTheme.focusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        onChanged: widget.onAssetPathChanged,
      ),
    );
  }

  Widget _cropIconBtn() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          widget.expandImage.value = !widget.expandImage.value;
        });
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        fixedSize: const Size.fromRadius(19),
        shape: const CircleBorder(),
        backgroundColor: const Color.fromARGB(165, 58, 58, 58),
      ),
      child: const SizedBox(
        width: 35,
        height: 35,
        child: CustomExpandIcon(),
      ),
    );
  }

  Widget _multiSelectBtn(bool multiSelectionModeValue) {
    return ElevatedButton(
      onPressed: () {
        if (multiSelectionModeValue) widget.clearMultiImages();
        setState(() {
          widget.multiSelectionMode.value = !multiSelectionModeValue;
        });
      },
      style: widget.multiSelectIconBtnStyle ??
          ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromRadius(19),
            shape: const CircleBorder(),
            backgroundColor: multiSelectionModeValue
                ? widget.appTheme.accentColor
                : const Color.fromARGB(165, 58, 58, 58),
          ),
      child: Center(
        child: (widget.multiSelectIconBtnStyle == null
                ? widget.multiSelectIcon
                : widget.multiSelectIcon?.copyWith(
                    color: multiSelectionModeValue
                        ? widget.appTheme.accentColor
                        : widget.multiSelectIcon?.color,
                  )) ??
            Transform.scale(
              alignment: Alignment.center,
              scaleX: -1,
              child: const Icon(
                Icons.filter_none,
                color: Colors.white,
                size: 19,
              ),
            ),
      ),
    );
  }

  Widget _cameraBtn(bool multiSelectionModeValue) {
    return ElevatedButton(
      onPressed: widget.moveToCamera,
      style: widget.cameraBtnStyle ??
          ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromRadius(19),
            shape: const CircleBorder(),
            backgroundColor: const Color.fromARGB(165, 58, 58, 58),
          ),
      child: Center(
        child: widget.cameraIcon ??
            const Icon(Icons.photo_camera_outlined,
                color: Colors.white, size: 20),
      ),
    );
  }
}
