import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_wcs/enums/wcs_plugin_listener_type_enum.dart';
import 'package:flutter_wcs/utils/enum_util.dart';
// import 'package:logger/logger.dart';

class WCSPluginListener {
  // static Logger _logger = Logger();

  static Set<WCSPluginListenerValue> listeners = {};

  WCSPluginListener(MethodChannel channel) {
    channel.setMethodCallHandler((methodCall) async {
      // 解析参数
      Map<String, dynamic> arguments = jsonDecode(methodCall.arguments);

      switch (methodCall.method) {
        case 'onListener':
          WCSPluginListenerTypeEnum type = EnumUtil.nameOf(WCSPluginListenerTypeEnum.values, arguments['type'])!;
          var originalParams = arguments["params"];
          // 回调触发
          for (var item in listeners) {
            item(type, originalParams);
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  void addListener(WCSPluginListenerValue func) {
    listeners.add(func);
  }

  void removeListener(WCSPluginListenerValue func) {
    listeners.remove(func);
  }
}

/// 监听器值模型
typedef WCSPluginListenerValue<P> = void Function(WCSPluginListenerTypeEnum type, P? params);
