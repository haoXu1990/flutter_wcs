import 'package:flutter/material.dart';

enum KameraEffectEnum {
  /// 切换摄像头
  swap,

  /// 闪关灯
  flash,
}

class FlareKameraEffectsWidget extends StatefulWidget {
  final void Function(KameraEffectEnum)? onTapEffects;
  const FlareKameraEffectsWidget({Key? key, this.onTapEffects}) : super(key: key);

  @override
  _FlareKameraEffectsWidgetState createState() => _FlareKameraEffectsWidgetState();
}

class _FlareKameraEffectsWidgetState extends State<FlareKameraEffectsWidget> {
  final imageList = [
    "assets/images/icon_camere_switch.png",
    "assets/images/icon_camera_flash.png",
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.onTapEffects?.call(KameraEffectEnum.swap);
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(imageList[0]),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.onTapEffects?.call(KameraEffectEnum.flash);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Image.asset(imageList[1]),
          ),
        ),
      ],
    );
  }
}
