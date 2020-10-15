import 'package:flutter/material.dart';
import 'package:media_picker_builder/data/album.dart';
import 'package:media_picker_builder/data/media_file.dart';
import 'package:media_picker_builder/media_picker_builder.dart';
import 'package:provider/provider.dart';

import 'gallery_widget.dart';
import 'multi_selector_model.dart';

class PickerWidget extends StatefulWidget {
  final bool withImages;
  final bool withVideos;
  final Function(Set<MediaFile> selectedFiles) onDone;
  final Function() onCancel;

  PickerWidget(
      {@required this.withImages,
      @required this.withVideos,
      @required this.onDone,
      @required this.onCancel});

  @override
  State<StatefulWidget> createState() => PickerWidgetState();
}

class PickerWidgetState extends State<PickerWidget> {
  List<Album> _albums;
  Album _selectedAlbum;
  bool _loading = true;
  MultiSelectorModel _selector = MultiSelectorModel();

  @override
  void initState() {
    super.initState();
    MediaPickerBuilder.getAlbums(
      withImages: widget.withImages,
      withVideos: widget.withVideos,
    ).then((albums) {
      setState(() {
        _loading = false;
        _albums = albums;
        if (albums.isNotEmpty) {
          albums.sort((a, b) => b.files.length.compareTo(a.files.length));
          _selectedAlbum = albums[0];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Center(child: CircularProgressIndicator())
        : _buildWidget();
  }

  _buildWidget() {
    if (_albums.isEmpty)
      return Center(child: Text("You have no folders to select from"));

    final dropDownAlbumsWidget = DropdownButton<Album>(
      value: _selectedAlbum,
      onChanged: (Album newValue) {
        setState(() {
          _selectedAlbum = newValue;
        });
      },
      items: _albums.map<DropdownMenuItem<Album>>((Album album) {
        return DropdownMenuItem<Album>(
          value: album,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 150),
            child: Text(
              "${album.name} (${album.files.length})",
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );

    return ChangeNotifierProvider<MultiSelectorModel>(
      builder: (context) => _selector,
      child: Container(
        height: double.infinity,
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 50,
                  child: FlatButton(
                    padding: EdgeInsets.all(0),
                    textColor: Colors.blue,
                    onPressed: () => widget.onCancel(),
                    child: Text("Cancel"),
                  ),
                ),
                dropDownAlbumsWidget,
                Consumer<MultiSelectorModel>(
                  builder: (context, selector, child) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 60),
                      child: FlatButton(
                        padding: EdgeInsets.all(0),
                        textColor: Colors.blue,
                        onPressed: () => widget.onDone(_selector.selectedItems),
                        child: Text(
                          "Done (${selector.selectedItems.length})",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            GalleryWidget(mediaFiles: _selectedAlbum.files),
          ],
        ),
      ),
    );
  }
}
