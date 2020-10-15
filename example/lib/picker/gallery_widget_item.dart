import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';
import 'package:provider/provider.dart';

import 'multi_selector_model.dart';

class GalleryWidgetItem extends StatefulWidget {
  final MediaFile mediaFile;

  GalleryWidgetItem({this.mediaFile});

  @override
  State<StatefulWidget> createState() => GalleryWidgetItemState();
}

class GalleryWidgetItemState extends State<GalleryWidgetItem> {
  Widget blueCheckCircle = Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      Icon(Icons.check_circle, color: Colors.blue)
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiSelectorModel>(
      builder: (context, selector, child) {
        return GestureDetector(
          onTap: () => selector.toggle(widget.mediaFile),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: selector.isSelected(widget.mediaFile) ? 0.7 : 1.0,
                child: child,
              ),
              selector.isSelected(widget.mediaFile)
                  ? Positioned(
                      right: 10,
                      bottom: 10,
                      child: blueCheckCircle,
                    )
                  : const SizedBox(),
            ],
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          widget.mediaFile.thumbnailPath != null
              ? RotatedBox(
                  quarterTurns: Platform.isIOS || widget.mediaFile.type == MediaType.VIDEO
                      ? 0
                      : MediaPickerBuilder.orientationToQuarterTurns(
                          widget.mediaFile.orientation),
                  child: Image.file(
                    File(widget.mediaFile.thumbnailPath),
                    fit: BoxFit.cover,
                  ),
                )
              : FutureBuilder(
                  future: MediaPickerBuilder.getThumbnail(
                    fileId: widget.mediaFile.id,
                    type: widget.mediaFile.type,
                  ),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      var thumbnail = snapshot.data;
                      widget.mediaFile.thumbnailPath = thumbnail;
                      return RotatedBox(
                        quarterTurns: Platform.isIOS || widget.mediaFile.type == MediaType.VIDEO
                            ? 0 // iOS thumbnails have correct orientation
                            : MediaPickerBuilder.orientationToQuarterTurns(
                                widget.mediaFile.orientation),
                        child: Image.file(
                          File(thumbnail),
                          fit: BoxFit.cover,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Icon(Icons.error, color: Colors.red, size: 24);
                    } else {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
          widget.mediaFile.type == MediaType.VIDEO
              ? Icon(Icons.play_circle_filled, color: Colors.white, size: 24)
              : const SizedBox()
        ],
      ),
    );
  }
}
