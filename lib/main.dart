import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _file;
  final picker = ImagePicker();
  bool _isVideo = false;
  VideoPlayerController? _controller;

  Future getImage(ImageSource imageSource) async {
    var pickedFile = await picker.getImage(source: imageSource);
    File? croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile!.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    setState(() {
      if (croppedFile != null) {
        _file = croppedFile;
        _isVideo = false;
      } else {
        print('No image selected.');
      }
    });
  }

  Future getVideo(ImageSource imageSource) async {
    final pickedFile = await picker.getVideo(source: imageSource);
    _file = File(pickedFile!.path);
    _controller = VideoPlayerController.file(_file!);
    await _controller!.initialize();
    await _controller!.setLooping(true);
    // await _controller.play();
    setState(() {
      // ignore: unnecessary_null_comparison
      if (pickedFile != null) {
        print("Video picked: ${pickedFile.path}");
        _isVideo = true;
      } else {
        print('No image selected.');
      }
    });
    _controller!.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker Example'),
      ),
      body: Center(
        child: _file == null
            ? Text('No image selected.')
            : _isVideo
                ? VideoPlayer(_controller!)
                : Image.file(_file!),
      ),
      floatingActionButton: Wrap(children: [
        FloatingActionButton(
          tooltip: 'Pick Image',
          child: Icon(Icons.add_a_photo),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Pick an image"),
                actions: [
                  ListTile(
                    title: Text("Camera"),
                    onTap: () {
                      getImage(ImageSource.camera);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text("Gallery"),
                    onTap: () {
                      getImage(ImageSource.gallery);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(
          width: 10,
        ),
        FloatingActionButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text("Pick an Video"),
                        actions: [
                          ListTile(
                            title: Text("Camera"),
                            onTap: () {
                              getVideo(ImageSource.camera);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text("Gallery"),
                            onTap: () {
                              getVideo(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ));
            },
            tooltip: 'Add a video',
            child: Icon(Icons.add)),
      ]),
    );
  }
}
