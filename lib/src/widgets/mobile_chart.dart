import 'dart:math';
import 'package:candlesticks/candlesticks.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/mainwindow_indicator_widget.dart';
import 'package:candlesticks/src/widgets/price_column.dart';
import 'package:candlesticks/src/widgets/time_row.dart';
import 'package:candlesticks/src/widgets/volume_widget.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/src/models/tooltip_side.dart';

import 'candles_zoom_clipper.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class MobileChart extends StatefulWidget {
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture
  final Function onScaleUpdate;

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  final int index;

  /// holds main window indicators data and high and low prices.
  final MainWindowDataContainer mainWindowDataContainer;

  /// How chart price range will be adjusted when moving chart
  final ChartAdjust chartAdjust;

  final CandleSticksStyle style;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  final void Function(String)? onRemoveIndicator;

  final Function() onReachEnd;
  final Function() onPrepareEnd;

  /// Билдер для подсказки, при лонг тапе на свечке
  final Widget Function(Candle)? tooltipBuilder;

  MobileChart({
    required this.style,
    required this.onScaleUpdate,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.chartAdjust,
    required this.onPanDown,
    required this.onPanEnd,
    required this.onReachEnd,
    required this.onPrepareEnd,
    required this.mainWindowDataContainer,
    required this.onRemoveIndicator,
    this.tooltipBuilder,
  });

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? longPressX;
  double? longPressY;
  bool showIndicatorNames = false;
  double? manualScaleHigh;
  double? manualScaleLow;
  TooltipSide _tooltipSide = TooltipSide.right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        // visible candles start and end indexes
        final int candlesStartIndex = max(widget.index, 0);
        final int candlesEndIndex = min(
            maxWidth ~/ widget.candleWidth + widget.index,
            widget.candles.length - 1);

        final maxCandlesOnScreen = maxWidth ~/ widget.candleWidth;
        final prepareOnCandlesBeforeEnd = 2 * maxCandlesOnScreen;

        if (candlesEndIndex >=
            widget.candles.length - prepareOnCandlesBeforeEnd) {
          Future(() {
            widget.onPrepareEnd();
          });
        }

        if (candlesEndIndex == widget.candles.length - 1) {
          Future(() {
            widget.onReachEnd();
          });
        }

        List<Candle> inRangeCandles = widget.candles
            .getRange(candlesStartIndex, candlesEndIndex + 1)
            .toList();

        double candlesHighPrice = 0;
        double candlesLowPrice = 0;
        if (manualScaleHigh != null) {
          candlesHighPrice = manualScaleHigh!;
          candlesLowPrice = manualScaleLow!;
        } else if (widget.chartAdjust == ChartAdjust.visibleRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs
              .getRange(candlesStartIndex, candlesEndIndex + 1)
              .reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows
              .getRange(candlesStartIndex, candlesEndIndex + 1)
              .reduce(min);
        } else if (widget.chartAdjust == ChartAdjust.fullRange) {
          candlesHighPrice = widget.mainWindowDataContainer.highs.reduce(max);
          candlesLowPrice = widget.mainWindowDataContainer.lows.reduce(min);
        }

        if (candlesHighPrice == candlesLowPrice) {
          candlesHighPrice += 10;
          candlesLowPrice -= 10;
        }

        // calculate priceScale
        double chartHeight = maxHeight * 0.75 - 2 * MAIN_CHART_VERTICAL_PADDING;

        // calculate highest volume
        double volumeHigh = inRangeCandles.map((e) => e.volume).reduce(max);

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressY = min(longPressY!, maxHeight);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesHighPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 0),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesLowPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 0),
              builder: (context, double low, _) {
                if (longPressX != null) {
                  _tooltipSide = longPressX! < maxWidth / 2
                      ? TooltipSide.right
                      : TooltipSide.left;
                }
                final currentCandle = longPressX == null
                    ? null
                    : widget.candles[min(
                        max(
                            (maxWidth - longPressX!) ~/ widget.candleWidth +
                                widget.index,
                            0),
                        widget.candles.length - 1)];
                return Container(
                  color: widget.style.background,
                  child: Stack(
                    children: [
                      TimeRow(
                        style: widget.style,
                        indicatorX: longPressX,
                        candles: widget.candles,
                        candleWidth: widget.candleWidth,
                        indicatorTime: currentCandle?.date,
                        index: widget.index,
                      ),
                      ClipRect(
                        clipper: CandlesZoomClipper(),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(width: 1),
                                            ),
                                          ),
                                          child: AnimatedPadding(
                                            duration: Duration(
                                              milliseconds: 0,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical:
                                                  MAIN_CHART_VERTICAL_PADDING,
                                            ),
                                            child: RepaintBoundary(
                                              child: Stack(
                                                children: [
                                                  MainWindowIndicatorWidget(
                                                    indicatorDatas: widget
                                                        .mainWindowDataContainer
                                                        .indicatorComponentData,
                                                    index: widget.index,
                                                    candleWidth:
                                                        widget.candleWidth,
                                                    low: low,
                                                    high: high,
                                                  ),
                                                  CandleStickWidget(
                                                    candles: widget.candles,
                                                    candleWidth:
                                                        widget.candleWidth,
                                                    index: widget.index,
                                                    high: high,
                                                    low: low,
                                                    bearColor: widget
                                                        .style.primaryBear,
                                                    bullColor: widget
                                                        .style.primaryBull,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  PriceColumn(
                                    style: widget.style,
                                    low: candlesLowPrice,
                                    high: candlesHighPrice,
                                    width: constraints.maxWidth,
                                    chartHeight: chartHeight,
                                    lastCandle: widget.candles[
                                        widget.index < 0 ? 0 : widget.index],
                                    onScale: (delta) {
                                      if (manualScaleHigh == null) {
                                        manualScaleHigh = candlesHighPrice;
                                        manualScaleLow = candlesLowPrice;
                                      }
                                      setState(() {
                                        double deltaPrice = delta /
                                            chartHeight *
                                            (manualScaleHigh! -
                                                manualScaleLow!);
                                        manualScaleHigh =
                                            manualScaleHigh! + deltaPrice;
                                        manualScaleLow =
                                            manualScaleLow! - deltaPrice;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(width: 1),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: VolumeWidget(
                                        candles: widget.candles,
                                        barWidth: widget.candleWidth,
                                        index: widget.index,
                                        high:
                                            HelperFunctions.getRoof(volumeHigh),
                                        bearColor: widget.style.secondaryBear,
                                        bullColor: widget.style.secondaryBull,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: DATE_BAR_HEIGHT,
                            ),
                          ],
                        ),
                      ),
                      longPressX != null
                          ? Positioned(
                              child: Container(
                                width: 1,
                                height: maxHeight - 8,
                                color: widget.style.mobileCandleHoverColor,
                              ),
                              right: (maxWidth - longPressX!),
                            )
                          : Container(),
                      if (widget.tooltipBuilder != null && longPressX != null)
                        Align(
                          alignment: _tooltipSide == TooltipSide.right
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          child: IgnorePointer(
                            child: widget.tooltipBuilder!.call(
                              _currentCandle(maxWidth)!,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 0, bottom: 20),
                        child: GestureDetector(
                          onLongPressEnd: (_) {
                            setState(() {
                              longPressX = null;
                              longPressY = null;
                            });
                          },
                          onScaleEnd: (_) {
                            widget.onPanEnd();
                          },
                          onScaleUpdate: (details) {
                            if (details.scale == 1) {
                              widget.onHorizontalDragUpdate(
                                details.focalPoint.dx,
                              );
                              setState(() {
                                if (manualScaleHigh != null) {
                                  double deltaPrice =
                                      details.focalPointDelta.dy /
                                          chartHeight *
                                          (manualScaleHigh! - manualScaleLow!);
                                  manualScaleHigh =
                                      manualScaleHigh! + deltaPrice;
                                  manualScaleLow = manualScaleLow! + deltaPrice;
                                }
                              });
                            }
                            widget.onScaleUpdate(details.horizontalScale);
                          },
                          onScaleStart: (details) {
                            widget.onPanDown(details.localFocalPoint.dx);
                          },
                          onLongPressStart: (LongPressStartDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
                          behavior: HitTestBehavior.translucent,
                          onLongPressMoveUpdate:
                              (LongPressMoveUpdateDetails details) {
                            setState(() {
                              longPressX = details.localPosition.dx;
                              longPressY = details.localPosition.dy;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Candle? _currentCandle(double maxWidth) {
    return longPressX == null
        ? null
        : widget.candles[min(
            max((maxWidth - longPressX!) ~/ widget.candleWidth + widget.index,
                0),
            widget.candles.length - 1)];
  }

  @override
  void dispose() {
    mainWindowDataContainer = null;
    super.dispose();
  }
}
