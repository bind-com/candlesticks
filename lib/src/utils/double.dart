import 'package:flutter/material.dart';

extension DoubleExtensions on double {
  String rounded({
    int afterZerosCountSkip = 3,
    int maxFractionLength = 5,
  }) {
    final parts = toString().split('.');

    final decimal = parts.first;
    final fraction = parts.last;

    final fraction1 = _removeZerosAndAfter(
      num: fraction,
      removeAfterCount: afterZerosCountSkip,
    );

    final fraction2 = _removeRedundantZeros(num: fraction1);
    final fraction3 = _removeRedundant(
      num: fraction2,
      maxLength: maxFractionLength,
    );

    if (fraction3.isEmpty) {
      return decimal;
    }

    return '$decimal.$fraction3';
  }

  String _removeZerosAndAfter({
    required String num,
    required int removeAfterCount,
  }) {
    final zerosSkippingPattern = List.generate(
      removeAfterCount,
      (_) => 0.toString(),
    ).join();

    final indexOfSkippingZeros = num.indexOf(zerosSkippingPattern);
    final hasZerosForSkip = indexOfSkippingZeros != -1;

    return hasZerosForSkip ? num.substring(0, indexOfSkippingZeros) : num;
  }

  String _removeRedundantZeros({required String num}) {
    final fractionChars = num.characters.toList();

    while (fractionChars.isNotEmpty) {
      if (fractionChars.last == 0.toString()) {
        fractionChars.removeLast();
        continue;
      }
      break;
    }
    return fractionChars.join();
  }

  String _removeRedundant({
    required String num,
    required int maxLength,
  }) {
    final chars = num.characters.toList();
    if (chars.length > maxLength) {
      chars.removeRange(maxLength, chars.length);
    }
    return chars.join();
  }
}
