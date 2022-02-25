import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var baseChennelControler: BaseChannelController!
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller = self.window.rootViewController as! FlutterViewController
//      BassChannelController.init(messenger: controller.binaryMessenger)
      baseChennelControler =  BaseChannelController.init(messenger: controller.binaryMessenger)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
