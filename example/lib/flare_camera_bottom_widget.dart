import 'package:flutter/material.dart';

class FlareCameraBottomWidget extends StatelessWidget {
  final void Function()? onTakePicture;
  const FlareCameraBottomWidget({Key? key, this.onTakePicture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: Colors.black,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTakePicture,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
