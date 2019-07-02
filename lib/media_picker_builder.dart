import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'package:media_picker_builder/data/album.dart';
import 'package:media_picker_builder/data/media_file.dart';

class MediaPickerBuilder {
  static const MethodChannel _channel =
      const MethodChannel('media_picker_builder');

  /// Gets list of albums and its content based on the required flags.
  /// This method will also return the thumbnails IF it was already generated.
  /// If thumbnails returned are null you will have to call {getThumbnail}
  /// to generate one and return its path
  static Future<List<Album>> getAlbums(
      {@required bool withImages, @required bool withVideos}) async {
    final String json = await _channel.invokeMethod(
      "getAlbums",
      {"withImages": withImages, "withVideos": withVideos},
    );
    final encoded = jsonDecode(json);
    return encoded.map<Album>((album) => Album.fromJson(album)).toList();
  }

  /// Returns the thumbnail path of the media file returned in method {getAlbums}.
  /// If there is no cached thumbnail for the file, it will generate one and return it.
  /// Android thumbnails will need to be rotated based on the file orientation.
  /// iOS thumbnails have the correct orientation
  /// i.e. RotatedBox(
  //                  quarterTurns: Platform.isIOS
  //                      ? 0
  //                      : orientationToQuarterTurns(mediaFile.orientation),
  //                  child: Image.file(
  //                    File(mediaFile.thumbnailPath),
  //                    fit: BoxFit.cover,
  //                    )
  static Future<String> getThumbnail(String fileId, MediaType type) async {
    final String path = await _channel
        .invokeMethod('getThumbnail', {"fileId": fileId, "type": type.index});
    print(path);
    return path;
  }

  /// A convenient function that converts image orientation to quarter turns for widget [RotatedBox]
  /// i.e. RotatedBox(
  //                   quarterTurns: orientationToQuarterTurns(mediaFile.orientation),
  //                   child: Image.file(
  //                     File(mediaFile.thumbnailPath),
  //                     fit: BoxFit.cover,
  //                     )
  static int orientationToQuarterTurns(int orientationInDegrees) {
    switch (orientationInDegrees) {
      case 90:
        return 1;
      case 180:
        return 2;
      case 270:
        return 3;
      default:
        return 0;
    }
  }
}
