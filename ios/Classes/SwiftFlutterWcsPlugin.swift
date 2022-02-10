import Flutter
import UIKit
import WCSiOS

public class SwiftFlutterWcsPlugin: NSObject, FlutterPlugin {
    public static var channel: FlutterMethodChannel?
    public static var wcsUploadClient: WCSClient?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_wcs", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterWcsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        SwiftFlutterWcsPlugin.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPlatformVersion" {
          result(getSystemVersion())
        } else if call.method == "normalUpload" {
            wcsNormalUpload(call: call, result: result)
        } else if call.method == "initSDK" {
            initSDK(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }

    public func initSDK(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            let error = FlutterError.init(code: "10001", message: "参数解析错误", details: "没有获取到有效参数")
            result(error)
            return
        }

        if let uploadDomain = arguments["uploadDomain"] as? String {
            // http://wpxq5tzp.up19.v1.wcsapi.com
            SwiftFlutterWcsPlugin.wcsUploadClient = WCSClient.init(baseURL: URL.init(string: uploadDomain )!,
                                                                   andTimeout: TimeInterval.init(30))
        }
        result(nil)
    }

    /// 获取系统版本
    /// - Returns: 当前 iOS 系统版本号
    public func getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
}

extension SwiftFlutterWcsPlugin {

    /// 网宿普通上传接口
    public func wcsNormalUpload(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            let error = FlutterError.init(code: "10001", message: "参数解析错误", details: "没有获取到有效参数")
            result(error)
            return
        }

        let request = WCSUploadObjectRequest.init()

        if let token = arguments["token"] as? String {
            request.token = token
        }

        if let fileURL = arguments["fileURL"] as? String {
            request.fileURL = URL.init(string: fileURL)
        }

        if let fileName = arguments["fileName"] as? String {
            request.fileName = fileName
        }

        if let key = arguments["key"] as? String {
            request.key = key
        }

        request.setUploadProgress { bytesSent, totaolBytesSent, totalBytesExpectedToSend in
            DispatchQueue.main.async {
                let params = [
                    "bytesSent": UInt64(bytesSent),
                    "totaolBytesSent": UInt64(totaolBytesSent),
                    "totalBytesExpectedToSend": UInt64(totalBytesExpectedToSend),
                ]

                SwiftFlutterWcsPlugin.invokeListener(type: .NormalUploadProgress, params: params)
            }
        }

        SwiftFlutterWcsPlugin.wcsUploadClient?.uploadRequest(request).continue({ task in
            if task.error != nil {
                DispatchQueue.main.async {
                    let error = FlutterError.init(code: "10002", message: "上传文件出错", details: task.error?.localizedDescription)
                    result(error)
                }
            } else {
                DispatchQueue.main.async {
                    result(true)
                }
            }
            return nil
        })
    }
}


extension SwiftFlutterWcsPlugin {

    public static func invokeListener(type: ListenerType, params: Any?) {
            var resultParams: [String: Any] = [:];
            resultParams["type"] = type;
            if let params = params {
                resultParams["params"] = params;
            }
        let result = JsonUtil.toJson(resultParams)
        SwiftFlutterWcsPlugin.channel!.invokeMethod("onListener", arguments: result)
    }
}
