import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/widgets/mobile_chart.dart';
import 'package:flutter/material.dart';

MainWindowDataContainer? mainWindowDataContainer;

enum ChartAdjust {
  /// Will adjust chart size by max and min value from visible area
  visibleRange,

  /// Will adjust chart size by max and min value from the whole data
  fullRange
}

/// StatefulWidget that holds Chart's State (index of
/// current position and candles width).
class Candlesticks extends StatefulWidget {
  /// The arrangement of the array should be such that
  /// the newest item is in position 0
  final List<Candle> candles;

  /// This callback calls when the last candle gets visible
  final Future<void> Function()? onLoadMoreCandles;

  /// List of buttons you what to add on top tool bar
  final List<ToolBarAction> actions;

  /// List of indicators to draw
  final List<Indicator>? indicators;

  /// This callback calls when ever user clicks a spcesific indicator close button (X)
  final void Function(String)? onRemoveIndicator;

  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;

  /// Will zoom buttons be displayed in toolbar
  final bool displayZoomActions;

  /// Custom loading widget
  final Widget? loadingWidget;

  final CandleSticksStyle? style;

  final Widget Function(Candle)? tooltipBuilder;

  const Candlesticks({
    Key? key,
    required this.candles,
    this.onLoadMoreCandles,
    this.actions = const [],
    this.chartAdjust = ChartAdjust.visibleRange,
    this.displayZoomActions = true,
    this.loadingWidget,
    this.indicators,
    this.onRemoveIndicator,
    this.style,
    this.tooltipBuilder,
  })  : assert(candles.length == 0 || candles.length > 1,
            "Please provide at least 2 candles"),
        super(key: key);

  @override
  _CandlesticksState createState() => _CandlesticksState();
}

class _CandlesticksState extends State<Candlesticks> {
  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  int index = -10;
  double lastX = 0;
  int lastIndex = -10;

  /// candleWidth controls the width of the single candles.
  ///  range: [2...10]
  double candleWidth = 6;

  /// true when widget.onLoadMoreCandles is fetching new candles.
  bool isCallingLoadMore = false;

  double beforeScaleCandleWidth = 6;

  @override
  void initState() {
    super.initState();
    if (widget.candles.length == 0) {
      return;
    }
    if (mainWindowDataContainer == null) {
      mainWindowDataContainer =
          MainWindowDataContainer(widget.indicators ?? [], widget.candles);
    }
  }

  @override
  void didUpdateWidget(covariant Candlesticks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles.length == 0) {
      return;
    }

    if (widget.candles.length < index) {
      index = -10;
    }

    if (mainWindowDataContainer == null) {
      mainWindowDataContainer = MainWindowDataContainer(
        widget.indicators ?? [],
        widget.candles,
      );
    } else {
      mainWindowDataContainer = MainWindowDataContainer(
        widget.indicators ?? [],
        widget.candles,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        (Theme.of(context).brightness == Brightness.dark
            ? CandleSticksStyle.dark()
            : CandleSticksStyle.light());
    if (widget.candles.length == 0 || mainWindowDataContainer == null)
      return Center(
        child: widget.loadingWidget ??
            CircularProgressIndicator(color: style.loadingColor),
      );
    return Stack(
      children: [
        TweenAnimationBuilder(
          tween: Tween(begin: 6.toDouble(), end: candleWidth),
          duration: Duration(milliseconds: 120),
          builder: (_, double width, __) {
            return MobileChart(
              style: style,
              onRemoveIndicator: widget.onRemoveIndicator,
              mainWindowDataContainer: mainWindowDataContainer!,
              chartAdjust: widget.chartAdjust,
              onScaleUpdate: (double scale) {
                /*scale = max(0.90, scale);
                scale = min(1.1, scale);*/
                setState(() {
                  candleWidth = beforeScaleCandleWidth * scale;
                  candleWidth = min(candleWidth, 20);
                  candleWidth = max(candleWidth, 2);
                });
              },
              onPanEnd: () {
                lastIndex = index;
                beforeScaleCandleWidth = candleWidth;
              },
              onHorizontalDragUpdate: (double x) {
                setState(() {
                  x = x - lastX;
                  index = lastIndex + x ~/ candleWidth;
                  index = max(index, -10);
                  index = min(index, widget.candles.length - 1);
                });
              },
              onPanDown: (double value) {
                lastX = value;
                lastIndex = index;
              },
              onReachEnd: () {
                if (isCallingLoadMore == false &&
                    widget.onLoadMoreCandles != null) {
                  isCallingLoadMore = true;
                  widget.onLoadMoreCandles!().then((_) {
                    isCallingLoadMore = false;
                  });
                }
              },
              onPrepareEnd: () {
                if (isCallingLoadMore == false &&
                    widget.onLoadMoreCandles != null) {
                  isCallingLoadMore = true;
                  widget.onLoadMoreCandles!().then((_) {
                    isCallingLoadMore = false;
                  });
                }
              },
              candleWidth: width,
              candles: widget.candles,
              index: index,
              tooltipBuilder: widget.tooltipBuilder,
            );
          },
        ),
      ],
    );
  }
}
