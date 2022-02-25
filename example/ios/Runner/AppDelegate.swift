import UIKit
import Flutter
//import NLEEditor
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller = self.window.rootViewController as! FlutterViewController
//      BassChannelController.init(messenger: controller.binaryMessenger)
      _ =  BaseChannelController.init(messenger: controller.binaryMessenger)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
