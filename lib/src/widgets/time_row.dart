import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/models/candle_sticks_style.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

class TimeRow extends StatefulWidget {
  final List<Candle> candles;
  final double candleWidth;
  final double? indicatorX;
  final DateTime? indicatorTime;
  final int index;
  final CandleSticksStyle style;

  const TimeRow({
    Key? key,
    required this.candles,
    required this.candleWidth,
    this.indicatorX,
    required this.indicatorTime,
    required this.index,
    required this.style,
  }) : super(key: key);

  @override
  State<TimeRow> createState() => _TimeRowState();
}

class _TimeRowState extends State<TimeRow> {
  final ScrollController _scrollController = new ScrollController();

  /// Calculates number of candles between two time indicator
  int _stepCalculator() {
    if (widget.candleWidth < 3)
      return 31;
    else if (widget.candleWidth < 5)
      return 19;
    else if (widget.candleWidth < 7)
      return 13;
    else
      return 9;
  }

  /// Calculates [DateTime] of a given candle index
  DateTime? _timeCalculator(int step, int index, Duration dif) {
    int candleNumber = (step + 1) ~/ 2 - 10 + index * step + -1;
    DateTime? _time;
    if (candleNumber < 0)
      _time = null;
    else if (candleNumber < widget.candles.length)
      _time = widget.candles[candleNumber].date;
    else {
      _time = widget.candles[0].date.subtract(
          Duration(milliseconds: dif.inMilliseconds ~/ step * candleNumber));
    }
    return _time;
  }

  /// Fomats number as 2 digit integer
  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  void didUpdateWidget(TimeRow oldWidget) {
    if (oldWidget.index != widget.index ||
        oldWidget.candleWidth != widget.candleWidth)
      _scrollController.jumpTo((widget.index + 10) * widget.candleWidth);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    int step = _stepCalculator() * 2;
    final dif =
        widget.candles[0].date.difference(widget.candles[1].date) * step;

    return Padding(
      padding: const EdgeInsets.only(right: 1.0),
      child: Stack(
        children: [
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.candles.length,
            scrollDirection: Axis.horizontal,
            itemExtent: step * widget.candleWidth,
            controller: _scrollController,
            reverse: true,
            itemBuilder: (context, index) {
              final _time = _timeCalculator(step, index, dif);
              if (_time == null) return SizedBox();
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      width: 1,
                      color: widget.style.borderColor,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd hh:mm').format(_time),
                    style: TextStyle(
                      color: widget.style.primaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
          widget.indicatorX == null
              ? Container()
              : Positioned(
                  bottom: 0,
                  left: math.max(widget.indicatorX! - 55, 0),
                  child: Container(
                    color: widget.style.hoverIndicatorBackgroundColor,
                    child: Center(
                      child: Text(
                        DateFormat('yyyy-MM-dd hh:mm').format(widget.indicatorTime!),
                        style: TextStyle(
                          color: widget.style.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    width: 110,
                    height: 20,
                  ),
                ),
        ],
      ),
    );
  }
}
