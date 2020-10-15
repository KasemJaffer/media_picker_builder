import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';

class ImageGridPage extends StatefulWidget {
  ImageGridPage({Key key}) : super(key: key);

  @override
  _ImageGridPageState createState() => _ImageGridPageState();
}

class _ImageGridPageState extends State<ImageGridPage> {
  List<MediaFile> _files = [];
  Map<String, String> thumbnailsCache = {};

  static const _imageSize = Size(90, 122);

  final _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    childAspectRatio: _imageSize.aspectRatio,
    mainAxisSpacing: 13,
    crossAxisSpacing: 13,
  );

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month, 30);

    MediaPickerBuilder.getMediaFilesBetween(start: start, end: end).then((files) {
      setState(() {
        _files = files;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Images"),
      ),
      body: CustomScrollView(
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final file = _files[index];

                final thumbnailFile = thumbnailsCache[file.id];
                if (thumbnailFile == null) {
                  fetchThumbnail(file);

                  return Container(
                    color: Colors.black,
                    height: _imageSize.height,
                    width: _imageSize.width,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Image.file(
                  File(thumbnailFile),
                  width: _imageSize.width,
                  height: _imageSize.height,
                  fit: BoxFit.cover,
                );
              },
              childCount: _files.length,
            ),
            gridDelegate: _gridDelegate,
          ),
          //   GridView.builder(
          //     padding: EdgeInsets.symmetric(vertical: 10),
          //     physics: NeverScrollableScrollPhysics(),
          //     itemBuilder: (context, index) {},
          //     itemCount: _files.length,
          //     gridDelegate: _gridDelegate,
          //   )
        ],
      ),
    );
  }

  Future<void> fetchThumbnail(MediaFile file) async {
    final filePath = await MediaPickerBuilder.getThumbnail(fileId: file.id, type: file.type);

    thumbnailsCache[file.id] = filePath;

    setState(() {});
  }
}
