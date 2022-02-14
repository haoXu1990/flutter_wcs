import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';

class FlareKameraFilterWidget extends StatefulWidget {
  final void Function()? onTakePicture;
  const FlareKameraFilterWidget({Key? key, this.onTakePicture}) : super(key: key);

  @override
  _FlareKameraFilterWidgetState createState() => _FlareKameraFilterWidgetState();
}

class _FlareKameraFilterWidgetState extends State<FlareKameraFilterWidget> {
  final imageList = [
    // "assets/images/icon_camera_filter_1.png",
    // "assets/images/icon_camera_filter_2.png",
    // "assets/images/icon_camera_filter_3.png",
    // "assets/images/icon_camera_filter_4.png",
    "assets/images/icon_camera_no_filter.png",
    "assets/images/icon_camera_filter_3.png",
    "assets/images/icon_camera_filter_3.png",
    "assets/images/icon_camera_filter_3.png",
    "assets/images/icon_camera_filter_1.png",
  ];

  Timer? _cameraTimer;
  int currentTimer = 0;

  void startTimer() {
    if (currentTimer > 0) return;
    _cameraTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      currentTimer += 100;
      if (currentTimer == 15000) {
        _cameraTimer?.cancel();
        currentTimer = 0;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      margin: const EdgeInsets.only(top: 100),
      height: 86,
      child: Stack(
        children: [
          Swiper(
            itemBuilder: (context, index) {
              return Image.asset(
                imageList[index],
              );
            },
            itemCount: imageList.length,
            viewportFraction: 0.3,
            itemWidth: 68,
            scale: 0.3,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              // 开始拍摄视频
              startTimer();
            },
            onLongPressEnd: (details) {
              _cameraTimer?.cancel();
              // 结束拍摄视频;
            },
            onTap: () {
              // 拍照
              print("点击拍照");
            },
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[400],
                  value: currentTimer / 15000,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
