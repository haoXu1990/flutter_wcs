import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wcs/listener/wcs_plugin_listener.dart';

class FlutterWcs {
  static const MethodChannel _channel = MethodChannel('flutter_wcs');
  static WCSPluginListener listener = WCSPluginListener(_channel);

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> normalUpload(String token,
      {required String? fileURL, required String? fileName, String? key, String? mimeType}) async {
    final params = {
      "fileURL": fileURL,
      "token": token,
      "fileName": fileName,
      "key": key,
    };
    return await _channel.invokeMethod("normalUpload", params);
  }

  /// 初始化
  static Future<void> initWCS(String uploadDomain) async {
    return await _channel.invokeMethod("initSDK", {"uploadDomain": uploadDomain});
  }

  static void addListener(WCSPluginListenerValue func) => listener.addListener(func);

  static void removeListener(WCSPluginListenerValue func) => listener.removeListener(func);
}
