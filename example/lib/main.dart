import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wcs/flutter_wcs.dart';
import 'package:flutter_wcs/utils/enum_util.dart';
import 'package:flutter_wcs_example/flare_kamera_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Demo",
      // home: MySwiperPage(),
      // home: FlareKameraPage(),
      home: MyApp(),
    );
  }
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
            onTap: videoToMp3,
            child: const Text('点我拍摄', style: TextStyle(fontSize: 24, color: Colors.red)),
          ),
        ),
      ),
    );
  }

  void videoToMp3() async {
    // ffmpeg -i test.mp4 -f mp3 -vn test.mp3

    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickVideo(source: ImageSource.gallery);
    final outPutFile = await getTemporaryDirectory();

    // final formatStr = "-i ${image!.path} -vn -acodec copy ${outPutFile.path}/test12332131231432.aac";
    // final formatStr = "-i ${image!.path} -r 5 -f image2 ${outPutFile.path}/img_%3d.jpg";

    // 多段的需要分开
    final formatStr = "-ss 00:00:00 -t 30 -i ${image!.path} ${outPutFile.path}/output_d.mp4";

    print(formatStr);
    FFmpegKit.execute(formatStr).then((value) async {
      final returnCode = await value.getReturnCode();
      if (returnCode?.isValueSuccess() == true) {
        print(true);
      } else {
        final logs = await value.getAllLogs();
        for (var item in logs) {
          print("${item.getMessage()}");
        }
      }
    });
  }

  // 拍摄
  void tapCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlareKameraPage(),
      ),
    );
  }

  // 上传文件
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
