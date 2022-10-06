import 'package:flutter/cupertino.dart';

import '../constant/view_constants.dart';

/// Нужен для того, чтобы график не отрисовывался за границами ограничений,
/// указанных в родительском виджете графика
class CandlesZoomClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    /// Вычитаем DATE_BAR_HEIGHT для того, чтобы не присходило отрисовки
    /// поверх списка дат (на оси x)
    return Rect.fromLTWH(0, 0, size.width, size.height - DATE_BAR_HEIGHT);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
