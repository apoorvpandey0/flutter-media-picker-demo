import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

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
  bool isUploading = false;
  bool isLoading = false;
  VideoPlayerController? _controller;
  FirebaseStorage storage = FirebaseStorage.instance;
  List<String> imageUrls = [];
  List<String> videoUrls = [];

  Future uploadImageToFirebase(
      BuildContext context, File _file, String folder) async {
    Reference ref =
        storage.ref().child("${folder}/file_" + DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(_file);
    print("Starting upload");
    final res = await uploadTask.then((res) {
      res.ref.getDownloadURL().then((value) => {print(value)});
    });
    print(res);
    print("Finished upload");
  }

  Future getImage(ImageSource imageSource) async {
    PickedFile? pickedFile =
        await picker.getImage(source: imageSource, imageQuality: 10);

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
    print("SIZE: ${croppedFile!.lengthSync()}");
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
    setState(() {
      isLoading = true;
    });
    final pickedFile = await picker.getVideo(source: imageSource);
    _file = File(pickedFile!.path);
    _controller = VideoPlayerController.file(_file!);
    await _controller!.initialize();
    await _controller!.setLooping(true);
    // await _controller.play();
    MediaInfo? mediaInfo = await VideoCompress.compressVideo(
      _file!.path,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false, // It's false by default
    );
    _file = mediaInfo!.file;
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
    setState(() {
      isLoading = false;
    });
  }

  Future getItems() async {
    imageUrls.clear();
    videoUrls.clear();
    var res = await storage.ref("images").listAll();
    for (var item in res.items) {
      String url = await item.getDownloadURL();
      imageUrls.add(url);
    }
    res = await storage.ref("videos").listAll();
    for (var item in res.items) {
      String url = await item.getDownloadURL();
      videoUrls.add(url);
    }
    setState(() {});
    print("Results: ${res.items}");
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker Example'),
      ),
      body: PageView(children: [
        isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: _file == null
                    ? Text('No image selected.')
                    : _isVideo
                        ? Column(
                            children: [
                              Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: VideoPlayer(_controller!)),
                              Text(
                                  "Size: ${((_file!.lengthSync()) / 1024).floor().toString()} Kb"),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.file(_file!),
                              Text(
                                  "Size: ${((_file!.lengthSync()) / 1024).floor().toString()} Kb"),
                            ],
                          ),
              ),
        ListView.builder(
            itemCount: imageUrls.length + videoUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 300,
                  // color: Colors.amber,
                  child: index < imageUrls.length
                      ? Image.network(imageUrls[index])
                      : GestureDetector(
                          onTap: () {
                            _launchURL(videoUrls[index - imageUrls.length]);
                          },
                          child: Container(
                              color: Colors.blue[100],
                              child: Text(videoUrls[index - imageUrls.length])),
                        ),
                ),
              );
            })
      ]),
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
        SizedBox(
          width: 10,
        ),
        FloatingActionButton(
          onPressed: () async {
            setState(() {
              isUploading = true;
            });
            await uploadImageToFirebase(
                context, _file!, _isVideo ? "videos" : "images");
            setState(() {
              isUploading = false;
            });
          },
          child: isUploading
              ? CircularProgressIndicator(
                  color: Colors.white,
                )
              : Icon(Icons.upload),
        ),
        SizedBox(
          width: 10,
        ),
        FloatingActionButton(
          onPressed: () async {
            await getItems();
          },
          child: Icon(Icons.download),
        )
      ]),
    );
  }
}
