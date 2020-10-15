import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_picker_builder/data/album.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:meta/meta.dart';

class MediaPickerBuilder {
  static const MethodChannel _channel = const MethodChannel('media_picker_builder');

  static Future<List<MediaFile>> getMediaFilesBetween({
    @required DateTime start,
    @required DateTime end,
    bool withImages = true,
    bool withVideos = true,
  }) async {
    assert(start != null);
    assert(end != null);

    final String json = await _channel.invokeMethod(
      "getMediaFilesBetween",
      {
        "startDate": start.millisecondsSinceEpoch / 1000,
        "endDate": end.millisecondsSinceEpoch / 1000,
        "withImages": withImages,
        "withVideos": withVideos,
      },
    );

    final files = await compute(_jsonToMediaFiles, json);

    return files;
  }

  /// Gets list of albums and its content based on the required flags.
  /// This method will also return the thumbnails IF it was already generated.
  /// If thumbnails returned are null you will have to call [getThumbnail]
  /// to generate one and return its path.
  /// [loadIOSPaths] For iOS only, to optimize the speed of querying the files you can set this to false,
  /// but if you do that you will have to get the path & video duration after selection is done
  static Future<List<Album>> getAlbums({
    @required bool withImages,
    @required bool withVideos,
    bool loadIOSPaths = true,
  }) async {
    final String json = await _channel.invokeMethod(
      "getAlbums",
      {
        "withImages": withImages,
        "withVideos": withVideos,
        "loadIOSPaths": loadIOSPaths,
      },
    );
    final albums = await compute(_jsonToAlbums, json);

    return albums;
  }

  /// Returns the thumbnail path of the media file returned in method [getAlbums].
  /// If there is no cached thumbnail for the file, it will generate one and return it.
  /// Android thumbnails will need to be rotated based on the file orientation.
  /// iOS thumbnails have the correct orientation
  /// i.e. RotatedBox(
  ///                  quarterTurns: Platform.isIOS
  ///                      ? 0
  ///                      : orientationToQuarterTurns(mediaFile.orientation),
  ///                  child: Image.file(
  ///                    File(mediaFile.thumbnailPath),
  ///                    fit: BoxFit.cover,
  ///                    )
  static Future<String> getThumbnail({
    @required String fileId,
    @required MediaType type,
  }) async {
    final String path = await _channel.invokeMethod(
      'getThumbnail',
      {
        "fileId": fileId,
        "type": type.index,
      },
    );
    return path;
  }

  /// Returns the [MediaFile] of a file by the unique identifier
  /// [loadIOSPath] Whether or not to try and fetch path & video duration for iOS.
  /// Android always returns the path & duration
  /// [loadThumbnail] Whether or not to generate a thumbnail
  static Future<MediaFile> getMediaFile({
    @required String fileId,
    @required MediaType type,
    bool loadIOSPath = true,
    bool loadThumbnail = false,
  }) async {
    final String json = await _channel.invokeMethod(
      'getMediaFile',
      {
        "fileId": fileId,
        "type": type.index,
        "loadIOSPath": loadIOSPath,
        "loadThumbnail": loadThumbnail,
      },
    );

    final file = await compute(_jsonToMediaFile, json);

    return file;
  }

  /// A convenient function that converts image orientation to quarter turns for widget [RotatedBox]
  /// i.e. RotatedBox(
  ///                  quarterTurns: orientationToQuarterTurns(mediaFile.orientation),
  ///                  child: Image.file(
  ///                    File(mediaFile.thumbnailPath),
  ///                    fit: BoxFit.cover,
  ///                    )
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

MediaFile _jsonToMediaFile(dynamic json) {
  final decoded = jsonDecode(json) as Map;
  final Map<String, dynamic> map = Map.castFrom(decoded);

  return MediaFile.fromJson(map);
}

List<MediaFile> _jsonToMediaFiles(dynamic json) {
  final decoded = jsonDecode(json) as List;
  final List<Map<String, dynamic>> list = List.castFrom(decoded);

  return list.map<MediaFile>((album) => MediaFile.fromJson(album)).toList();
}

List<Album> _jsonToAlbums(dynamic json) {
  final decoded = jsonDecode(json) as List;
  final List<Map<String, dynamic>> list = List.castFrom(decoded);

  return list.map<Album>((album) => Album.fromJson(album)).toList();
}
