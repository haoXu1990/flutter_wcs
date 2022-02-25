//
//  BassChannelController.swift
//  Runner
//
//  Created by XuHao on 2022/2/25.
//


class BassChannelController {
    var channel: FlutterBasicMessageChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterBasicMessageChannel.init(name: "com.wcs.fire.BaseMessageChannel", binaryMessenger: messenger)
        channel.setMessageHandler { message, reply in
            if let params = message as? Dictionary<String, Any> {
                
            }
        }
    }
}
