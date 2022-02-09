import Flutter
import UIKit
import WCSiOS

public class SwiftFlutterWcsPlugin: NSObject, FlutterPlugin {

    var wcsToken: String?
    var wcsUploadDomain: String?

    var wcsUploadClient: WCSClient!

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_wcs", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterWcsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        instance.wcsUploadClient = WCSClient.init(baseURL: URL.init(string: "http://wpxq5tzp.up19.v1.wcsapi.com")!, andTimeout: TimeInterval.init(30))
        NSLog("这里是 iOS Navite 初始化完成")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getPlatformVersion" {
          result(getSystemVersion())
        } else if call.method == "normalUpload" {
            wcsNomalUpload(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }

    /// 获取系统版本
    /// - Returns: 当前 iOS 系统版本号
    public func getSystemVersion() -> String {
        return UIDevice.current.systemVersion
    }
}

extension SwiftFlutterWcsPlugin {

    /// 网宿普通上传接口
    public func wcsNomalUpload(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            let error = FlutterError.init(code: "10001", message: "参数解析错误", details: "没有获取到有效参数")
            result(error)
            return
        }

        let request = WCSUploadObjectRequest.init()

        request.token = "xhv3UpQ8UBlOppftNVQpvz9M1z6BhY6uNZ2p:ZDMwNDVlODA1ZjQxNDFiMmJiOWNmNWUxMTljNTY2MzJiYTcyNGEyNw==:eyJzY29wZSI6ImZsYXJlYnVjazAxOmlPU1VwbG9hZFRlc3QucG5nIiwiZGVhZGxpbmUiOiIyNTI0NjIyNDAwMDAwIiwib3ZlcndyaXRlIjowLCJmc2l6ZUxpbWl0IjowfQ=="

        request.fileName = "IMG_0007-thumb"
        request.key = "IMG_0007-thumb"
        if let fileURL = arguments["fileURL"] as? String {
            request.fileURL = URL.init(string: fileURL)
            NSLog("获取到的文件 URL: \(String(describing: request.fileURL))")
        }

        request.key = ""
        NSLog("获取到的文件 URL: dfa")

        request.setUploadProgress { bytesSent, totaolBytesSent, totalBytesExpectedToSend in

            DispatchQueue.main.async {
                NSLog("======\(totaolBytesSent) \(totalBytesExpectedToSend)\n")
            }
        }

       self.wcsUploadClient.uploadRequest(request).continue({ task in
            if task.error != nil {
                result("哦豁，上传文件出错了")
            } else {
                result("恭喜你，上传文件成功")
            }
            return nil
        })

//        upLoadResult.set
//        result(upLoadResult.result?.resultString ?? "毛都没有")
    }
}
