import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_scanner_scan_file/media_scanner_scan_file.dart';
import 'check_permission.dart';

import 'package:image_picker/image_picker.dart';
import 'package:social_share/social_share.dart';

class TextOverImage extends StatefulWidget {
  @override
  _TextOverImage createState() => _TextOverImage();
}

class _TextOverImage extends State<TextOverImage> {
  var globalKey = new GlobalKey(); // 위젯 캡쳐를 위한 globalkey
  var file;
  var scanfile;
  Image _stickerImage;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Text Over Image Image Example'),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            // 캡쳐 바운더리 잡기
            RepaintBoundary(
              key: globalKey,
              child: Center(
                child: Container(
                  height: 300,
                  width: 300,
                  child: Stack(
                    children: <Widget>[
                      // 이미지 부분
                      FutureBuilder(
                          future: _loadImage(),
                          builder: (BuildContext context,
                              AsyncSnapshot<Image> image) {
                            if (image.hasData) {
                              return image.data; // image is ready
                            } else {
                              return new Container(); // placeholder
                            }
                          }),
                      HomePage() // 글자 표시
                    ],
                  ),
                ),
              ),
            ),
            RaisedButton(
              child: Text("CAPTURE"),
              onPressed: _capture,
            ),
            RaisedButton(
              //갤러리에서 이미지 파일을 가져오는 버튼
              child: Text("gallery"),
              onPressed: () {
                // social_share => 고른 위의 파일의 경로를 가지고 story에 업로드한다.
                SocialShare.shareInstagramStory(file.path, "#ffffff", "#000000",
                        "https://deep-link-url")
                    .then((data) {
                  print(data);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _capture() async {
    bool status = await checkPermission(); // 권한 check 및 팝업

    print("START CAPTURE");
    var renderObject = globalKey.currentContext.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      var boundary = renderObject;
      ui.Image image = await boundary.toImage();
      // final directory = (await getExternalStorageDirectory()).path;
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      // print(pngBytes);
      // print(directory);

      // file path + file name 로 파일 객체 생성
      //File imgFile = new File('$directory/screenshot.png');
      File imgFile = new File('/storage/emulated/0/Download/screenshot.png');
      imgFile.writeAsBytes(pngBytes); // png 파일 저장
      _scanFile(imgFile); // media scan
      file = imgFile;
      print("FINISH CAPTURE ${imgFile.path}");
    } else {
      print("!");
    }
  }

  Future<Image> _loadImage() async {
    file = await ImagePicker.pickImage(source: ImageSource.gallery);

    _stickerImage = new Image.file(file);

    return _stickerImage;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Offset offset = Offset.zero;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Positioned(
        left: offset.dx,
        top: offset.dy,
        child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                offset = Offset(
                    offset.dx + details.delta.dx, offset.dy + details.delta.dy);
              });
            },
            child: SizedBox(
              width: 300,
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text("Zero Hero",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.0,
                          color: Colors.black)),
                ),
              ),
            )),
      ),
    );
  }
}

Future<String> _scanFile(File f) async {
  final result = await MediaScannerScanFile.scanFile(f.path);
  return result['filePath'];
}
