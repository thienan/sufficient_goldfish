import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'utils.dart';

class ProfilePicture extends StatefulWidget {
  final bool editing;
  final Uri _imageFile;
  final Function updateLocalValuesCallback;

  ProfilePicture(
      this.editing, this.updateLocalValuesCallback,
      [this._imageFile]);

  @override
  State<ProfilePicture> createState() => new _ProfilePictureState(_imageFile);
}

class _ProfilePictureState extends State<ProfilePicture> {
  Uri _imageFile;
  _ProfilePictureState(this._imageFile);

  @override
  Widget build(BuildContext context) {
    var image = new Card(
        child: _imageFile == null
            ? new Image.asset('assets/fish-silhouette.png')
            : (_imageFile.toString().startsWith('http')
            ? new Image.network(_imageFile.toString(), fit: BoxFit.cover)
            : new Image.file(new File.fromUri(_imageFile),
            fit: BoxFit.cover)));
    if (widget.editing) {
      return new Stack(
        children: [
          new Container(
            child: image,
            foregroundDecoration: new BoxDecoration(
                color: new Color.fromRGBO(200, 200, 200, 0.5)),
          ),
          new IconButton(
            iconSize: 50.0,
            onPressed: _getImage,
            tooltip: 'Pick Image',
            icon: new Icon(Icons.add_a_photo),
          ),
        ],
        alignment: new Alignment(0.0, 0.0),
      );
    } else {
      return image;
    }
  }

  _getImage() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = imageFile.uri;
    });
    await _uploadToStorage(imageFile);
  }

  Future<Null> _uploadToStorage(File imageFile) async {
    var random = new Random().nextInt(10000);
    var ref = FirebaseStorage.instance.ref().child('image_$random.jpg');
    var uploadTask = ref.put(imageFile);
    var downloadUrl = (await uploadTask.future).downloadUrl;
    widget.updateLocalValuesCallback(downloadUrl.toString());
  }
}

Widget createScrollableProfile(BuildContext context, bool editing, FocusNode focus, MatchData data, Widget extras) {
  return CustomScrollView(
      slivers: scrollableProfilePictures(editing, data)
        ..add(new SliverList(
          delegate: SliverChildListDelegate(
            <Widget>[
              _showData('Name', 'e.g. Frank', Icons.person, editing, focus, (changed) => data.name = changed),
              _showData('Favorite Music',
                  'e.g. Blubstep', Icons.music_note, editing, focus, (changed) => data.favoriteMusic = changed),
              _showData('Favorite pH level', 'e.g. 5',
                  Icons.beach_access, editing, focus, (changed) => data.favoritePh = changed),
              extras,
            ],
          ),
        )));
}

Widget _showData(String label, String hintText, IconData iconData, bool editing, FocusNode focus, Function onChanged) {
  return new TextField(
    decoration: new InputDecoration(
        labelText: label, icon: new Icon(iconData), hintText: hintText),
    onSubmitted: onChanged,
    focusNode: focus,
    enabled: editing,
  );
}


List<Widget> scrollableProfilePictures(bool editable, MatchData matchData) {
  var tiles = new List.generate(4,
          (i) => new ProfilePicture(editable, (value) => matchData.setImageData(i, value), matchData.getImage(i)));

  var mainImage = tiles.removeAt(0);
  return <Widget>[
    new SliverList(
      delegate: SliverChildListDelegate([mainImage]),
    ),
    new SliverGrid(
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 4.0),
        delegate: new SliverChildListDelegate(tiles)),
  ];
}