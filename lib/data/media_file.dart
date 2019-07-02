class MediaFile {
  String id;
  int dateAdded;
  String path;
  String thumbnailPath;
  int orientation;
  MediaType type;

  MediaFile(
      {this.id, this.dateAdded, this.path, this.thumbnailPath, this.orientation, this.type});

  MediaFile.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        dateAdded = json['dateAdded'],
        path = json['path'],
        thumbnailPath = json['thumbnailPath'],
        orientation = json['orientation'],
        type = MediaType.values[json['type']];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MediaFile &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum MediaType { IMAGE, VIDEO }
