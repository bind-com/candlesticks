import 'package:flutter/cupertino.dart';

import '../constant/view_constants.dart';

class CandlesZoomClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height - DATE_BAR_HEIGHT);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
