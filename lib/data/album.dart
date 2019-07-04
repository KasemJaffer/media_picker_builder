import 'package:media_picker_builder/data/media_file.dart';

class Album {
  /// Unique identifier for the album
  final String id;
  final String name;
  final List<MediaFile> files;

  Album({this.id, this.name, this.files});

  Album.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        files = json['files']
            .map<MediaFile>((json) => MediaFile.fromJson(json))
            .toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
