import 'package:flutter/material.dart';
import 'package:flutter_wcs/flutter_wcs.dart';
import 'package:photo_album_manager/photo_album_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: GestureDetector(
            onTap: tap,
            child: const Text('点我上传', style: TextStyle(fontSize: 24, color: Colors.red)),
          ),
        ),
      ),
    );
  }

  void tap() async {
    List<AlbumModelEntity> photos = await PhotoAlbumManager.getDescAlbum(maxCount: 10);
    final entity = photos.first;
    print(entity.toJson());

    // 调用插件
    final result = await FlutterWcs.normalUpload(fileURL: entity.thumbPath);
    print(result);
  }
}
