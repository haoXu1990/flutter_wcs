import 'package:flutter/material.dart';

class FlareCameraCloseWidget extends StatelessWidget {
  final void Function()? onTapClose;
  const FlareCameraCloseWidget({Key? key, this.onTapClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTapClose,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
