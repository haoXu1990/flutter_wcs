import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWcs {
  static const MethodChannel _channel = MethodChannel('flutter_wcs');

  late String wcsToken;
  late String wcsUploadDomain;
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> normalUpload({String? fileURL, String? fileName, String? mimeType}) async {
    return await _channel.invokeMethod("normalUpload", {"fileURL": fileURL});
  }

  /// 初始化
  Future<void> initWCS(String token, String uploadDomain) async {
    wcsToken = token;
    wcsUploadDomain = uploadDomain;
    return;
  }
}
