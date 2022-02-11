import 'package:flutter/material.dart';
import 'package:flutter_wcs/flutter_wcs.dart';
import 'package:flutter_wcs/utils/enum_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final Logger _logger = Logger();
  @override
  void initState() {
    super.initState();
    FlutterWcs.addListener(_listener);
    FlutterWcs.initWCS("http://wpxq5tzp.up19.v1.wcsapi.com");
  }

  @override
  void dispose() {
    FlutterWcs.removeListener(_listener);
    super.dispose();
  }

  _listener(type, params) {
    _logger.d("[${EnumUtil.getEnumName(type)}]:$params");
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
    // List<AlbumModelEntity> photos = await PhotoAlbumManager.getDescAlbum(maxCount: 10);
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);

    const wcsToken =
        "xhv3UpQ8UBlOppftNVQpvz9M1z6BhY6uNZ2p:N2Q5NmI2MDMyYjQyNjFiY2JlZjk1N2QxOWI1ZDc1YjNlNTY4NTRjNA==:eyJzY29wZSI6ImZsYXJlYnVjazAxOmlPU1VwbG9hZFRlc3QubXA0IiwiZGVhZGxpbmUiOiIyNTI0NjIyNDAwMDAwIiwib3ZlcndyaXRlIjoxLCJmc2l6ZUxpbWl0IjowfQ==";
    // const wcsToken =
    //     "xhv3UpQ8UBlOppftNVQpvz9M1z6BhY6uNZ2p:NzYzNmEzYTI5ZWE1NGI2M2FjNWM5NTY5ZGJlMDhkMzQwZGFkMTk1Mg==:eyJzY29wZSI6InVwbG9hZHR0dDppT1NVcGxvYWRUZXN0Lm1wNCIsImRlYWRsaW5lIjoiMjUyNDYyMjQwMDAwMCIsIm92ZXJ3cml0ZSI6MSwiZnNpemVMaW1pdCI6MH0=";
    // 调用插件
    try {
      final result = await FlutterWcs.normalUpload(wcsToken, fileName: "iOSUploadTest", fileURL: image!.path);
      _logger.d(result);
    } catch (e) {
      _logger.d(e.toString());
    }
  }
}
