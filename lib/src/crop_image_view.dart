import 'dart:io';
import 'package:image_picker_plus/src/custom_expand_icon.dart';
import 'package:image_picker_plus/src/entities/app_theme.dart';
import 'package:image_picker_plus/src/custom_packages/crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/entities/path_wrapper.dart';
import 'package:image_picker_plus/src/scale_text.dart';
import 'package:photo_manager/photo_manager.dart';

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

  final AppTheme appTheme;
  final ValueNotifier<bool> noDuration;
  final Color whiteColor;
  final double? topPosition;

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
    this.assetPathSelected,
    this.topPosition,
  }) : super(key: key);

  @override
  State<CropImageView> createState() => _CropImageViewState();
}

class _CropImageViewState extends State<CropImageView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.enableVerticalTapping,
      builder: (context, bool enableTappingValue, child) => GestureDetector(
        onVerticalDragUpdate: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandImageView.value = true;
                widget.expandHeight.value = details.globalPosition.dy - 56;
                setState(() => widget.noDuration.value = true);
              }
            : null,
        onVerticalDragEnd: enableTappingValue && widget.topPosition != null
            ? (details) {
                widget.expandHeight.value =
                    widget.expandHeight.value > 260 ? 418 : 0;
                if (widget.topPosition == -418) {
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

    String path = selectedImageValue.path;
    bool isThatVideo = path.contains("mp4", path.length - 5);

    return Container(
      key: GlobalKey(debugLabel: "have image"),
      color: widget.whiteColor,
      height: 416,
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
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _pathsDropDownButton(),
          const Spacer(),
          if (widget.topPosition != null)
            _multiSelectIconBtn(multiSelectionModeValue),
        ],
      ),
    );
  }

  Widget _pathsDropDownButton() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<PathWrapper<AssetPathEntity>>(
        value: widget.assetPathSelected,
        items: widget.assetPaths.map(
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
                      style: const TextStyle(fontSize: 17),
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
                          color: Colors.grey,
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
                style: const TextStyle(fontSize: 17),
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
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.expandImage.value = !widget.expandImage.value;
          });
        },
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: const Color.fromARGB(165, 58, 58, 58),
            border: Border.all(
              color: const Color.fromARGB(45, 250, 250, 250),
            ),
            shape: BoxShape.circle,
          ),
          child: const CustomExpandIcon(),
        ),
      ),
    );
  }

  Widget _multiSelectIconBtn(bool multiSelectionModeValue) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          if (multiSelectionModeValue) widget.clearMultiImages();
          setState(() {
            widget.multiSelectionMode.value = !multiSelectionModeValue;
          });
        },
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: multiSelectionModeValue
                ? widget.appTheme.accentColor
                : const Color.fromARGB(165, 58, 58, 58),
            border: Border.all(
              color: const Color.fromARGB(45, 250, 250, 250),
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.copy, color: Colors.white, size: 17),
          ),
        ),
      ),
    );
  }
}
